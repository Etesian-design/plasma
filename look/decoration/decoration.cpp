#include "decoration.h"
#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/DecorationShadow>
#include <KPluginFactory>
#include <QDir>
#include <QIcon>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QSettings>
#include <QtMath>

K_PLUGIN_FACTORY_WITH_JSON(EtesianDecorationFactory, "metadata.json", registerPlugin<Etesian::Decoration>();)

namespace Etesian
{
static constexpr qreal HEADER = 44, BUTTON = 30, BUTTON_TOP = 7, EDGE = 4, SPACER = 10, RADIUS = 8, ICON = 22;
static const QColor RED(0xDA, 0x20, 0x1E), RED_PRESSED(0xA8, 0x15, 0x0F);

/** A squircle (superellipse, n = 2.8 as measured on N9 icons: every side curves), the shape of every thumb-sized icon and button highlight in the Etesian look. */
static QPainterPath squircle(const QRectF &r)
{
    QPainterPath p;
    const qreal a = r.width() / 2, b = r.height() / 2, cx = r.center().x(), cy = r.center().y();
    for (int i = 0; i <= 72; ++i) {
        const qreal t = i * 2 * M_PI / 72, c = qCos(t), s = qSin(t);
        const QPointF pt(cx + a * (c < 0 ? -1 : 1) * qPow(qAbs(c), 2 / 2.8), cy + b * (s < 0 ? -1 : 1) * qPow(qAbs(s), 2 / 2.8));
        i ? p.lineTo(pt) : p.moveTo(pt);
    }
    p.closeSubpath();
    return p;
}

/** kwinrc [Etesian]: HeaderActions (on by default) and HeaderActionApps, the apps whose toolbar moves into the header. */
static QSettings &config()
{
    static QSettings s(QDir::homePath() + QStringLiteral("/.config/kwinrc"), QSettings::IniFormat);
    s.sync();
    return s;
}

Decoration::Decoration(QObject *parent, const QVariantList &args)
    : KDecoration3::Decoration(parent, args)
{
}

Decoration::~Decoration()
{
    if (m_app) m_app->setToolBarHidden(false); // the window is closing or the decoration changes: the app keeps its toolbar
}

bool Decoration::init()
{
    auto *w = window();
    setBorders(QMarginsF(0, HEADER, 0, 0));
    setResizeOnlyBorders(QMarginsF(4, 4, 4, 4));

    m_controls = new KDecoration3::DecorationButtonGroup(this);
    m_controls->setSpacing(0);
    for (auto t : {KDecoration3::DecorationButtonType::Minimize, KDecoration3::DecorationButtonType::Maximize, KDecoration3::DecorationButtonType::Close})
        m_controls->addButton(new Button(t, this, m_controls));
    m_actionGroup = new KDecoration3::DecorationButtonGroup(this);
    m_actionGroup->setSpacing(2);
    m_appMenu = new Button(KDecoration3::DecorationButtonType::ApplicationMenu, this, this);

    // a soft shadow, like the design's window shadow (smaller when inactive is left to KWin)
    auto shadow = std::make_shared<KDecoration3::DecorationShadow>();
    QImage img(96, 96, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    {
        QPainter p(&img);
        p.setRenderHint(QPainter::Antialiasing);
        for (int i = 0; i < 24; ++i) {
            p.setPen(Qt::NoPen);
            p.setBrush(QColor(0, 0, 0, int(5 + i * 0.6)));
            p.drawRoundedRect(QRectF(i, i + 6, 96 - 2 * i, 96 - 2 * i - 6), RADIUS + 24 - i, RADIUS + 24 - i);
        }
    }
    shadow->setShadow(img);
    shadow->setPadding(QMarginsF(24, 18, 24, 30));
    shadow->setInnerShadowRect(QRectF(48, 48, 1, 1));
    setShadow(shadow);

    m_app = new AppActions(this);
    connect(m_app, &AppActions::changed, this, &Decoration::rebuildActions);
    connect(w, &KDecoration3::DecoratedWindow::widthChanged, this, &Decoration::relayout);
    connect(w, &KDecoration3::DecoratedWindow::maximizedChanged, this, [this] { relayout(); update(); });
    connect(w, &KDecoration3::DecoratedWindow::activeChanged, this, [this] { update(); });
    connect(w, &KDecoration3::DecoratedWindow::captionChanged, this, [this] { update(); });
    connect(w, &KDecoration3::DecoratedWindow::iconChanged, this, [this] { update(); });
    connect(w, &KDecoration3::DecoratedWindow::applicationMenuChanged, this, &Decoration::updateMenu);
    connect(w, &KDecoration3::DecoratedWindow::hasApplicationMenuChanged, this, &Decoration::updateMenu);
    updateMenu();
    relayout();
    return true;
}

bool Decoration::enabled() const
{
    return config().value(QStringLiteral("Etesian/HeaderActions"), true).toBool();
}

bool Decoration::listed() const
{
    const QStringList apps = config().value(QStringLiteral("Etesian/HeaderActionApps"), QStringList{QStringLiteral("org.kde.kate"), QStringLiteral("org.kde.kwrite")}).toStringList();
    const QStringList cls = window()->windowClass().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const QString &c : cls)
        if (apps.contains(c, Qt::CaseInsensitive)) return true;
    return false;
}

void Decoration::updateMenu()
{
    auto *w = window();
    m_appMenu->setVisible(w->hasApplicationMenu());
    // listed apps are always followed: with HeaderActions off they get their own toolbar back (it may have been hidden before)
    if (w->hasApplicationMenu() && listed()) m_app->setMenu(w->applicationMenuServiceName(), w->applicationMenuObjectPath());
    else m_app->setMenu(QString(), QString());
    relayout();
}

void Decoration::rebuildActions()
{
    for (auto *b : m_actionGroup->buttons()) {
        m_actionGroup->removeButton(b);
        b->deleteLater();
    }
    const QList<AppAction> list = enabled() ? m_app->actions() : QList<AppAction>();
    for (const AppAction &a : list) {
        auto *b = new Button(KDecoration3::DecorationButtonType::Custom, this, m_actionGroup, a.icon);
        b->setEnabled(a.enabled);
        const int id = a.id;
        const QString tip = a.label;
        connect(b, &KDecoration3::DecorationButton::clicked, m_app, [this, id] { m_app->trigger(id); });
        connect(b, &KDecoration3::DecorationButton::hoveredChanged, this, [this, tip](bool on) { on ? requestShowToolTip(tip) : requestHideToolTip(); });
        m_actionGroup->addButton(b);
    }
    m_actionsOn = !list.isEmpty();
    m_app->setToolBarHidden(m_actionsOn); // the header now carries the toolbar's actions: one row of chrome
    relayout();
    update();
}

void Decoration::relayout()
{
    const qreal w = window()->width();
    setTitleBar(QRectF(0, 0, w, HEADER));
    for (auto *b : m_controls->buttons()) b->setGeometry(QRectF(0, 0, BUTTON, BUTTON));
    m_controls->setPos(QPointF(w - EDGE - m_controls->geometry().width(), BUTTON_TOP));
    qreal x = m_controls->geometry().left() - SPACER;
    m_dividerX = x + SPACER / 2;
    if (m_appMenu->isVisible()) {
        x -= BUTTON;
        m_appMenu->setGeometry(QRectF(x, BUTTON_TOP, BUTTON, BUTTON));
    }
    for (auto *b : m_actionGroup->buttons()) b->setGeometry(QRectF(0, 0, BUTTON + 4, BUTTON));
    if (!m_actionGroup->buttons().isEmpty()) {
        x -= m_actionGroup->geometry().width() + 4;
        m_actionGroup->setPos(QPointF(x, BUTTON_TOP));
    }
    m_titleRight = x - 8;
    update();
}

void Decoration::paint(QPainter *painter, const QRectF &repaintArea)
{
    Q_UNUSED(repaintArea)
    auto *w = window();
    const bool active = w->isActive(), max = w->isMaximized();
    const QRectF bar(0, 0, w->width(), HEADER);
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);

    // the header: the chrome surface, lit from the top; rounded top corners unless maximised
    QLinearGradient g(0, 0, 0, HEADER);
    g.setColorAt(0, active ? QColor(0x3A, 0x3A, 0x3A) : QColor(0x2A, 0x2A, 0x2A));
    g.setColorAt(1, active ? QColor(0x14, 0x14, 0x14) : QColor(0x1E, 0x1E, 0x1E));
    QPainterPath shape;
    const qreal r = max ? 0 : RADIUS;
    shape.moveTo(0, HEADER);
    shape.lineTo(0, r);
    shape.arcTo(QRectF(0, 0, 2 * r, 2 * r), 180, -90);
    shape.lineTo(bar.width() - r, 0);
    shape.arcTo(QRectF(bar.width() - 2 * r, 0, 2 * r, 2 * r), 90, -90);
    shape.lineTo(bar.width(), HEADER);
    shape.closeSubpath();
    painter->fillPath(shape, g);

    // inactive windows: header content at half strength
    painter->setOpacity(active ? 1.0 : 0.5);

    // the app squircle: the window's icon cut to the squircle
    const QRectF iconRect(10, (HEADER - ICON) / 2, ICON, ICON);
    painter->save();
    painter->setClipPath(squircle(iconRect));
    w->icon().paint(painter, iconRect.toAlignedRect());
    painter->restore();

    // the title, in the light face
    QFont f = w->decoration()->settings()->font();
    f.setPixelSize(21);
    f.setWeight(QFont::Light);
    painter->setFont(f);
    painter->setPen(Qt::white);
    const QRectF titleRect(iconRect.right() + 10, 0, qMax<qreal>(0, m_titleRight - iconRect.right() - 10), HEADER);
    painter->drawText(titleRect, Qt::AlignVCenter | Qt::AlignLeft, QFontMetricsF(f).elidedText(w->caption(), Qt::ElideRight, titleRect.width()));

    // the divider between the app's buttons and the window controls
    if (m_actionsOn || m_appMenu->isVisible()) painter->fillRect(QRectF(m_dividerX, (HEADER - 24) / 2, 1, 24), QColor(255, 255, 255, 41));
    painter->restore();

    m_actionGroup->paint(painter, repaintArea);
    if (m_appMenu->isVisible()) m_appMenu->paint(painter, repaintArea);
    m_controls->paint(painter, repaintArea);
}

Button::Button(KDecoration3::DecorationButtonType type, Decoration *decoration, QObject *parent, const QString &icon)
    : KDecoration3::DecorationButton(type, decoration, parent)
    , m_icon(icon)
{
    setGeometry(QRectF(0, 0, BUTTON, BUTTON));
    connect(this, &DecorationButton::hoveredChanged, this, [this] { update(); });
    connect(this, &DecorationButton::pressedChanged, this, [this] { update(); });
}

void Button::paint(QPainter *painter, const QRectF &repaintArea)
{
    Q_UNUSED(repaintArea)
    if (!isVisible()) return;
    auto *deco = qobject_cast<Decoration *>(decoration());
    const bool active = deco->window()->isActive();
    const QRectF g = geometry();
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setOpacity(active ? 1.0 : 0.5);
    const bool close = type() == KDecoration3::DecorationButtonType::Close;
    // the hover / pressed highlight: a squircle (red for close)
    if (isEnabled() && (isHovered() || isPressed())) {
        const QRectF s = QRectF(0, 0, 26, 26).translated(g.center() - QPointF(13, 13));
        painter->fillPath(squircle(s), close ? (isPressed() ? RED_PRESSED : RED) : QColor(255, 255, 255, isPressed() ? 61 : 41));
    }
    QPen pen(Qt::white, 1.8, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
    painter->setPen(pen);
    painter->setBrush(Qt::NoBrush);
    painter->translate(g.topLeft() + QPointF((g.width() - BUTTON) / 2, 0));
    switch (type()) {
    case KDecoration3::DecorationButtonType::Minimize:
        painter->drawLine(QPointF(10, 15.5), QPointF(20, 15.5));
        break;
    case KDecoration3::DecorationButtonType::Maximize:
        if (isChecked()) {
            painter->drawRect(QRectF(10, 13, 7, 7));
            QPainterPath back;
            back.moveTo(13, 13); back.lineTo(13, 10); back.lineTo(20, 10); back.lineTo(20, 17); back.lineTo(17, 17);
            painter->drawPath(back);
        } else {
            painter->drawRect(QRectF(10.5, 10.5, 9, 9));
        }
        break;
    case KDecoration3::DecorationButtonType::Close:
        painter->drawLine(QPointF(10.5, 10.5), QPointF(19.5, 19.5));
        painter->drawLine(QPointF(19.5, 10.5), QPointF(10.5, 19.5));
        break;
    case KDecoration3::DecorationButtonType::ApplicationMenu: // the app menu: "…"
        painter->setPen(Qt::NoPen);
        painter->setBrush(Qt::white);
        for (qreal x : {9.0, 15.0, 21.0}) painter->drawEllipse(QPointF(x, 15), 1.5, 1.5);
        break;
    default: { // an app action: its theme icon, drawn white; dimmed when the app has it disabled
        QPixmap pm = QIcon::fromTheme(m_icon).pixmap(QSize(20, 20), painter->device()->devicePixelRatioF());
        QPainter tint(&pm);
        tint.setCompositionMode(QPainter::CompositionMode_SourceIn);
        tint.fillRect(pm.rect(), Qt::white);
        tint.end();
        if (!isEnabled()) painter->setOpacity(painter->opacity() * 0.35);
        painter->drawPixmap(QRectF(5, 5, 20, 20), pm, pm.rect());
    }
    }
    painter->restore();
}
}

#include "decoration.moc"
