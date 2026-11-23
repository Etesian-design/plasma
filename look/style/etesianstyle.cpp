// SPDX-License-Identifier: AGPL-3.0-only
// The Etesian widget style: Breeze, with the controls the Etesian Design Language draws its own way (etesian-design
// src/components: HdButton, HdTextField, HdSlider, HdCheckBox, HdRadioButton, HdProgressBar) drawn as there:
// - buttons and combo boxes: squircle-half ends (the N9's, n = 2.8), lit from the top, a 1 px rim; flat and darker when pressed;
//   the default/checked button in the accent;
// - text fields: the same ends, a rim that turns to the focus colour (2 px) when focused;
// - sliders: a 4 px dark groove with an inset shadow, the accent up to the value, a 30 px top-lit white squircle knob with a
//   soft shadow;
// - check boxes: a squircle with its rim following the curve, filled with the accent and a white tick when checked;
// - radio buttons: the same squircle with a 12 px accent squircle in it;
// - progress bars: a 6 px pill, the accent over the divider colour.
// Everything else is Breeze's. Colours come from the palette (the Etesian colour scheme), the accent from Highlight.
#include <QPainter>
#include <QPainterPath>
#include <QProxyStyle>
#include <QStyleFactory>
#include <QStyleOption>
#include <QStylePlugin>
#include <QtMath>

namespace {

constexpr double N = 2.8;

// The N9 superellipse in a rect.
QPainterPath squircle(const QRectF &r)
{
    QPainterPath p;
    const double a = r.width() / 2, b = r.height() / 2, cx = r.center().x(), cy = r.center().y();
    for (int i = 0; i < 96; ++i) {
        const double t = i / 96.0 * 2 * M_PI, c = qCos(t), s = qSin(t);
        const QPointF pt(cx + a * (c < 0 ? -1 : 1) * qPow(qAbs(c), 2 / N), cy + b * (s < 0 ? -1 : 1) * qPow(qAbs(s), 2 / N));
        i ? p.lineTo(pt) : p.moveTo(pt);
    }
    p.closeSubpath();
    return p;
}

// Squircle-half ends: the left and right halves of a squircle as tall as the rect, joined by straight top and bottom edges.
QPainterPath capsule(const QRectF &r)
{
    const double h = r.height();
    if (r.width() <= h)
        return squircle(r);
    QPainterPath p;
    const double rr = h / 2, cy = r.center().y();
    const double lx = r.left() + rr, rx = r.right() - rr;
    bool first = true;
    auto arc = [&](double cx, double from) {
        for (int i = 0; i <= 24; ++i) {
            const double t = from + i / 24.0 * M_PI, c = qCos(t), s = qSin(t);
            const QPointF pt(cx + rr * (c < 0 ? -1 : 1) * qPow(qAbs(c), 2 / N), cy + rr * (s < 0 ? -1 : 1) * qPow(qAbs(s), 2 / N));
            first ? p.moveTo(pt) : p.lineTo(pt);
            first = false;
        }
    };
    arc(rx, -M_PI / 2); // right end, top to bottom
    arc(lx, M_PI / 2);  // left end, bottom to top
    p.closeSubpath();
    return p;
}

QColor mix(const QColor &a, const QColor &b, double t)
{
    return QColor::fromRgbF(a.redF() + (b.redF() - a.redF()) * t, a.greenF() + (b.greenF() - a.greenF()) * t,
                            a.blueF() + (b.blueF() - a.blueF()) * t, a.alphaF() + (b.alphaF() - a.alphaF()) * t);
}

// Top-lit: a little lighter at the top, a little darker at the bottom (the design's --hd-lit-fill).
QLinearGradient lit(const QRectF &r, const QColor &base)
{
    QLinearGradient g(r.topLeft(), r.bottomLeft());
    g.setColorAt(0, mix(base, Qt::white, 0.16));
    g.setColorAt(0.5, base);
    g.setColorAt(1, mix(base, Qt::black, 0.10));
    return g;
}

bool dark(const QPalette &pal)
{
    return pal.color(QPalette::Window).lightness() < 128;
}

class EtesianStyle : public QProxyStyle
{
public:
    EtesianStyle()
        : QProxyStyle(QStyleFactory::create(QStringLiteral("Breeze")))
    {
    }

    int pixelMetric(PixelMetric m, const QStyleOption *opt, const QWidget *w) const override
    {
        switch (m) {
        case PM_SliderThickness:
        case PM_SliderLength:
        case PM_SliderControlThickness:
            return 30;
        case PM_IndicatorWidth:
        case PM_IndicatorHeight:
        case PM_ExclusiveIndicatorWidth:
        case PM_ExclusiveIndicatorHeight:
            return 20;
        default:
            return QProxyStyle::pixelMetric(m, opt, w);
        }
    }

    void drawPrimitive(PrimitiveElement pe, const QStyleOption *opt, QPainter *p, const QWidget *w) const override
    {
        switch (pe) {
        case PE_PanelButtonCommand:
        case PE_PanelButtonBevel:
            if (auto b = qstyleoption_cast<const QStyleOptionButton *>(opt); b && (b->features & QStyleOptionButton::Flat) && !(b->state & (State_Sunken | State_On | State_MouseOver)))
                return; // flat buttons: nothing until hovered or pressed, as Breeze
            drawButton(opt, p, opt->state & State_On);
            return;
        case PE_FrameLineEdit:
        case PE_PanelLineEdit:
            if (auto f = qstyleoption_cast<const QStyleOptionFrame *>(opt); f && f->lineWidth <= 0 && pe == PE_PanelLineEdit)
                return; // a frameless edit (inside a combo box or spin box) gets no frame of its own
            drawField(opt, p);
            return;
        case PE_IndicatorCheckBox:
            drawCheck(opt, p);
            return;
        case PE_IndicatorRadioButton:
            drawRadio(opt, p);
            return;
        default:
            QProxyStyle::drawPrimitive(pe, opt, p, w);
        }
    }

    void drawControl(ControlElement ce, const QStyleOption *opt, QPainter *p, const QWidget *w) const override
    {
        switch (ce) {
        case CE_PushButtonBevel:
            if (auto b = qstyleoption_cast<const QStyleOptionButton *>(opt)) {
                if ((b->features & QStyleOptionButton::Flat) && !(b->state & (State_Sunken | State_On | State_MouseOver)))
                    return;
                drawButton(opt, p, (b->features & QStyleOptionButton::DefaultButton) || (b->state & State_On));
                return;
            }
            break;
        case CE_ProgressBarGroove:
            if (auto b = qstyleoption_cast<const QStyleOptionProgressBar *>(opt)) {
                p->save();
                p->setRenderHint(QPainter::Antialiasing);
                p->setPen(Qt::NoPen);
                p->setBrush(mix(b->palette.color(QPalette::Window), b->palette.color(QPalette::WindowText), 0.18)); // divider
                p->drawRoundedRect(bar(b), 3, 3);
                p->restore();
                return;
            }
            break;
        case CE_ProgressBarContents:
            if (auto b = qstyleoption_cast<const QStyleOptionProgressBar *>(opt)) {
                const QRectF g = bar(b);
                const qint64 span = qint64(b->maximum) - b->minimum;
                if (span <= 0)
                    break; // busy: Breeze's moving bar
                const double f = qBound(0.0, double(b->progress - b->minimum) / span, 1.0);
                if (f <= 0)
                    return;
                p->save();
                p->setRenderHint(QPainter::Antialiasing);
                p->setPen(Qt::NoPen);
                p->setBrush(b->palette.color(QPalette::Highlight));
                QRectF fill = g;
                if (b->state & State_Horizontal || b->rect.width() > b->rect.height())
                    b->direction == Qt::RightToLeft ? fill.setLeft(g.right() - g.width() * f) : fill.setWidth(g.width() * f);
                else
                    fill.setTop(g.bottom() - g.height() * f);
                p->drawRoundedRect(fill, 3, 3);
                p->restore();
                return;
            }
            break;
        default:
            break;
        }
        QProxyStyle::drawControl(ce, opt, p, w);
    }

    void drawComplexControl(ComplexControl cc, const QStyleOptionComplex *opt, QPainter *p, const QWidget *w) const override
    {
        if (cc == CC_Slider) {
            if (auto s = qstyleoption_cast<const QStyleOptionSlider *>(opt)) {
                drawSlider(s, p, w);
                return;
            }
        }
        if (cc == CC_ComboBox) {
            if (auto c = qstyleoption_cast<const QStyleOptionComboBox *>(opt); c && c->frame) {
                if (c->editable)
                    drawField(opt, p);
                else
                    drawButton(opt, p, false);
                // the arrow and the rest, without Breeze's frame
                QStyleOptionComboBox o(*c);
                o.frame = false;
                QProxyStyle::drawComplexControl(cc, &o, p, w);
                return;
            }
        }
        QProxyStyle::drawComplexControl(cc, opt, p, w);
    }

private:
    static QRectF bar(const QStyleOptionProgressBar *b)
    {
        const QRectF r = b->rect;
        if (r.width() >= r.height())
            return QRectF(r.left(), r.center().y() - 3, r.width(), 6);
        return QRectF(r.center().x() - 3, r.top(), 6, r.height());
    }

    void drawButton(const QStyleOption *opt, QPainter *p, bool accent) const
    {
        const QPalette &pal = opt->palette;
        const bool pressed = opt->state & State_Sunken, enabled = opt->state & State_Enabled;
        const QRectF r = QRectF(opt->rect).adjusted(1.5, 1.5, -1.5, -1.5);
        const QColor base = accent ? pal.color(QPalette::Highlight) : pal.color(QPalette::Button);
        const QColor rim = accent ? mix(base, Qt::black, 0.18) : mix(pal.color(QPalette::Button), pal.color(QPalette::ButtonText), dark(pal) ? 0.22 : 0.28);
        p->save();
        p->setRenderHint(QPainter::Antialiasing);
        if (!enabled)
            p->setOpacity(0.5);
        const QPainterPath shape = capsule(r);
        if (pressed) { // flat and darker: the light leaves
            QLinearGradient g(r.topLeft(), r.bottomLeft());
            g.setColorAt(0, mix(base, Qt::black, 0.16));
            g.setColorAt(1, base);
            p->fillPath(shape, g);
        } else {
            p->fillPath(shape, lit(r, (opt->state & State_MouseOver) ? mix(base, Qt::black, 0.04) : base));
            // the top rim light, inside the shape
            p->save();
            p->setClipPath(shape);
            p->setPen(QPen(QColor(255, 255, 255, accent ? 70 : (dark(pal) ? 30 : 140)), 1));
            p->drawLine(QPointF(r.left() + r.height() / 2, r.top() + 1), QPointF(r.right() - r.height() / 2, r.top() + 1));
            p->restore();
        }
        p->setPen(QPen(rim, 1));
        p->setBrush(Qt::NoBrush);
        p->drawPath(shape);
        if (opt->state & State_HasFocus && opt->state & State_KeyboardFocusChange) {
            p->setPen(QPen(pal.color(QPalette::Highlight), 2));
            p->drawPath(capsule(r.adjusted(-1, -1, 1, 1)));
        }
        p->restore();
    }

    void drawField(const QStyleOption *opt, QPainter *p) const
    {
        const QPalette &pal = opt->palette;
        const bool focus = opt->state & State_HasFocus;
        const QRectF r = QRectF(opt->rect).adjusted(1.5, 1.5, -1.5, -1.5);
        p->save();
        p->setRenderHint(QPainter::Antialiasing);
        if (!(opt->state & State_Enabled))
            p->setOpacity(0.5);
        const QPainterPath shape = capsule(r);
        p->fillPath(shape, pal.color(QPalette::Base));
        const QColor edge = focus ? pal.color(QPalette::Highlight)
                                  : mix(pal.color(QPalette::Base), pal.color(QPalette::Text), (opt->state & State_MouseOver) ? 0.45 : 0.25);
        p->setPen(QPen(edge, focus ? 2 : 1));
        p->drawPath(focus ? capsule(r.adjusted(0.5, 0.5, -0.5, -0.5)) : shape);
        p->restore();
    }

    void drawCheck(const QStyleOption *opt, QPainter *p) const
    {
        const QPalette &pal = opt->palette;
        const bool on = opt->state & State_On, partial = opt->state & State_NoChange;
        const int side = qMin(opt->rect.width(), opt->rect.height());
        const QRectF r(opt->rect.x() + (opt->rect.width() - side) / 2.0, opt->rect.y() + (opt->rect.height() - side) / 2.0, side, side);
        p->save();
        p->setRenderHint(QPainter::Antialiasing);
        if (!(opt->state & State_Enabled))
            p->setOpacity(0.5);
        const QColor accent = pal.color(QPalette::Highlight);
        const QColor rim = (on || partial) ? accent : mix(pal.color(QPalette::Base), pal.color(QPalette::Text), 0.55);
        p->fillPath(squircle(r), rim);                                                                   // the rim is the whole shape
        p->fillPath(squircle(r.adjusted(2, 2, -2, -2)), (on || partial) ? accent : pal.color(QPalette::Base)); // the fill 2 px smaller
        p->setPen(QPen(Qt::white, side / 9.0, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
        if (on) {
            QPainterPath t;
            t.moveTo(r.left() + side * 0.27, r.top() + side * 0.52);
            t.lineTo(r.left() + side * 0.44, r.top() + side * 0.69);
            t.lineTo(r.left() + side * 0.74, r.top() + side * 0.34);
            p->drawPath(t);
        } else if (partial) {
            p->drawLine(QPointF(r.left() + side * 0.3, r.center().y()), QPointF(r.right() - side * 0.3, r.center().y()));
        }
        p->restore();
    }

    void drawRadio(const QStyleOption *opt, QPainter *p) const
    {
        const QPalette &pal = opt->palette;
        const bool on = opt->state & State_On;
        const int side = qMin(opt->rect.width(), opt->rect.height());
        const QRectF r(opt->rect.x() + (opt->rect.width() - side) / 2.0, opt->rect.y() + (opt->rect.height() - side) / 2.0, side, side);
        p->save();
        p->setRenderHint(QPainter::Antialiasing);
        if (!(opt->state & State_Enabled))
            p->setOpacity(0.5);
        const QColor accent = pal.color(QPalette::Highlight);
        p->fillPath(squircle(r), on ? accent : mix(pal.color(QPalette::Base), pal.color(QPalette::Text), 0.55));
        p->fillPath(squircle(r.adjusted(2, 2, -2, -2)), pal.color(QPalette::Base));
        if (on) {
            const double m = side * 0.6; // 12 px in 20
            p->fillPath(squircle(QRectF(r.center().x() - m / 2, r.center().y() - m / 2, m, m)), accent);
        }
        p->restore();
    }

    void drawSlider(const QStyleOptionSlider *s, QPainter *p, const QWidget *w) const
    {
        const QPalette &pal = s->palette;
        const QRect groove = subControlRect(CC_Slider, s, SC_SliderGroove, w);
        const QRect handle = subControlRect(CC_Slider, s, SC_SliderHandle, w);
        const bool horizontal = s->orientation == Qt::Horizontal;
        p->save();
        p->setRenderHint(QPainter::Antialiasing);
        if (!(s->state & State_Enabled))
            p->setOpacity(0.5);
        if (s->subControls & SC_SliderTickmarks) {
            QStyleOptionSlider o(*s);
            o.subControls = SC_SliderTickmarks;
            QProxyStyle::drawComplexControl(CC_Slider, &o, p, w);
        }
        if (s->subControls & SC_SliderGroove) {
            // 4 px, dark, nearly square ends, an inset shadow; the accent up to the knob
            const QRectF g = horizontal ? QRectF(groove.left() + 2, groove.center().y() - 1.5, groove.width() - 4, 4)
                                        : QRectF(groove.center().x() - 1.5, groove.top() + 2, 4, groove.height() - 4);
            p->setPen(Qt::NoPen);
            p->setBrush(QColor(0x3A, 0x3A, 0x3A));
            p->drawRoundedRect(g, 1, 1);
            QRectF fill = g;
            const bool upsideDown = s->upsideDown != (horizontal && s->direction == Qt::RightToLeft);
            if (horizontal)
                upsideDown ? fill.setLeft(handle.center().x()) : fill.setRight(handle.center().x());
            else
                upsideDown ? fill.setBottom(handle.center().y()) : fill.setTop(handle.center().y());
            p->setBrush(pal.color(QPalette::Highlight));
            p->drawRoundedRect(fill, 1, 1);
            p->setBrush(QColor(0, 0, 0, 110)); // inset shadow along the top edge
            p->drawRect(horizontal ? QRectF(g.left(), g.top(), g.width(), 1) : QRectF(g.left(), g.top(), 1, g.height()));
        }
        if (s->subControls & SC_SliderHandle) {
            // the knob: 30 px squircle, white lit from the top (#fff, #F1F1F2, #D6D6D9), a #B9B9BC rim, a soft shadow below
            const QRectF k = QRectF(handle.center().x() - 13.5, handle.center().y() - 14, 27, 27);
            for (int i = 3; i >= 1; --i)
                p->fillPath(squircle(k.translated(0, 1.5 + i * 0.6).adjusted(-i * 0.6, -i * 0.6, i * 0.6, i * 0.6)), QColor(0, 0, 0, 22));
            QLinearGradient g(k.topLeft(), k.bottomLeft());
            g.setColorAt(0, Qt::white);
            g.setColorAt(0.5, QColor(0xF1, 0xF1, 0xF2));
            g.setColorAt(1, QColor(0xD6, 0xD6, 0xD9));
            const QPainterPath knob = squircle(k);
            p->fillPath(knob, (s->state & State_Sunken) ? QBrush(QColor(0xE4, 0xE4, 0xE6)) : QBrush(g));
            p->setPen(QPen(QColor(0xB9, 0xB9, 0xBC), 1));
            p->setBrush(Qt::NoBrush); // the rim only (the groove's shadow brush would fill the knob dark)
            p->drawPath(knob);
        }
        p->restore();
    }
};

class EtesianStylePlugin : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "etesian.json")
public:
    QStyle *create(const QString &key) override
    {
        return key.compare(QLatin1String("etesian"), Qt::CaseInsensitive) == 0 ? new EtesianStyle : nullptr;
    }
};

} // namespace

#include "etesianstyle.moc"
