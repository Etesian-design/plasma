// The Etesian window decoration (etesian-design explorations/desktop2 XWin.vue, "10 · Window decorations"): one 44 px header
// bar per window, the app squircle and the title in the light face on the left, then the app's actions, the app menu (…), a thin
// divider and minimise / maximise / close; every button gets a squircle on hover (red for close). Inactive windows show the
// header content at half strength. KDE apps listed in kwinrc [Etesian] HeaderActionApps get their toolbar's actions here and
// their own toolbar hidden (kwinrc [Etesian] HeaderActions=false turns that off and gives the toolbars back).
#pragma once
#include "appactions.h"
#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationButton>
#include <KDecoration3/DecorationButtonGroup>
#include <QVariantList>

namespace Etesian
{
class Decoration : public KDecoration3::Decoration
{
    Q_OBJECT
public:
    explicit Decoration(QObject *parent = nullptr, const QVariantList &args = QVariantList());
    ~Decoration() override;
    bool init() override;
    void paint(QPainter *painter, const QRectF &repaintArea) override;
    bool headerActionsOn() const { return m_actionsOn; }

private:
    void relayout();
    void rebuildActions();
    void updateMenu();
    bool listed() const;  // the app is in HeaderActionApps
    bool enabled() const; // HeaderActions is on

    KDecoration3::DecorationButtonGroup *m_controls = nullptr;
    KDecoration3::DecorationButtonGroup *m_actionGroup = nullptr;
    KDecoration3::DecorationButton *m_appMenu = nullptr;
    AppActions *m_app = nullptr;
    bool m_actionsOn = false;
    qreal m_dividerX = -1;
    qreal m_titleRight = 0;
};

class Button : public KDecoration3::DecorationButton
{
    Q_OBJECT
public:
    Button(KDecoration3::DecorationButtonType type, Decoration *decoration, QObject *parent, const QString &icon = QString());
    void paint(QPainter *painter, const QRectF &repaintArea) override;

private:
    QString m_icon; // app actions: the theme icon, drawn white
};
}
