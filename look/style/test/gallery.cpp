// SPDX-License-Identifier: AGPL-3.0-only
// For the tests (test/scenarios/controls.sh) only: one window with every control the Etesian style draws, in the style Plasma
// is set to. Not installed.
#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QRadioButton>
#include <QSlider>
#include <QWidget>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QWidget w;
    w.setWindowTitle(QStringLiteral("Controls — %1").arg(app.style()->name()));
    auto form = new QFormLayout(&w);
    auto buttons = new QHBoxLayout;
    auto ok = new QPushButton(QStringLiteral("Save"));
    ok->setDefault(true);
    buttons->addWidget(ok);
    buttons->addWidget(new QPushButton(QStringLiteral("Cancel")));
    auto off = new QPushButton(QStringLiteral("Off"));
    off->setEnabled(false);
    buttons->addWidget(off);
    form->addRow(QStringLiteral("Buttons"), buttons);
    auto combo = new QComboBox;
    combo->addItems({QStringLiteral("Belle"), QStringLiteral("Harmattan")});
    form->addRow(QStringLiteral("Choice"), combo);
    form->addRow(QStringLiteral("Name"), new QLineEdit(QStringLiteral("Etesian")));
    auto slider = new QSlider(Qt::Horizontal);
    slider->setRange(0, 100);
    slider->setValue(60);
    form->addRow(QStringLiteral("Volume"), slider);
    auto checks = new QHBoxLayout;
    auto on = new QCheckBox(QStringLiteral("On"));
    on->setChecked(true);
    checks->addWidget(on);
    checks->addWidget(new QCheckBox(QStringLiteral("Off")));
    auto r1 = new QRadioButton(QStringLiteral("One"));
    r1->setChecked(true);
    checks->addWidget(r1);
    checks->addWidget(new QRadioButton(QStringLiteral("Two")));
    form->addRow(QStringLiteral("Options"), checks);
    auto progress = new QProgressBar;
    progress->setValue(40);
    progress->setTextVisible(false);
    form->addRow(QStringLiteral("Progress"), progress);
    w.resize(520, 330);
    w.show();
    // --shot <file>: the window as drawn, saved, then quit (no session needed: QT_QPA_PLATFORM=offscreen)
    if (const int i = app.arguments().indexOf(QStringLiteral("--shot")); i > 0 && i + 1 < app.arguments().size()) {
        app.processEvents();
        return w.grab().save(app.arguments().at(i + 1)) ? 0 : 1;
    }
    return app.exec();
}
