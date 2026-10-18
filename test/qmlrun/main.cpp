/*
 * qmlrun - compiles or runs a QML file, for checking a patch on a device.
 *
 *   qmlrun --compile <file.qml>   compile only: imports, types, properties
 *   qmlrun --run <file.qml>       create it without a window and run the event loop
 *   qmlrun --show <file.qml>      show it full screen in a QQuickView
 *
 * Exits non-zero on a compile or creation error. Qt 5.6 has no Qt.exit(), so
 * a test reports through its output and ends with Qt.quit().
 */

#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickView>
#include <QUrl>
#include <cstdio>

static int reportErrors(const QList<QQmlError> &errors)
{
    for (const QQmlError &error : errors)
        fprintf(stderr, "ERROR: %s\n", qPrintable(error.toString()));
    return errors.isEmpty() ? 0 : 1;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    const QStringList args = app.arguments();
    if (args.size() != 3) {
        fprintf(stderr, "usage: qmlrun --compile|--run|--show <file.qml>\n");
        return 2;
    }
    const QString mode = args.at(1);
    const QUrl url = QUrl::fromLocalFile(args.at(2));

    if (mode == QLatin1String("--show")) {
        QQuickView view;
        QObject::connect(view.engine(), &QQmlEngine::quit, &app, &QGuiApplication::quit);
        view.setResizeMode(QQuickView::SizeRootObjectToView);
        view.setSource(url);
        if (view.status() != QQuickView::Ready)
            return reportErrors(view.errors()) | 1;
        view.showFullScreen();
        return app.exec();
    }

    QQmlEngine engine;
    QObject::connect(&engine, &QQmlEngine::quit, &app, &QGuiApplication::quit);
    QQmlComponent component(&engine, url);
    if (component.isError())
        return reportErrors(component.errors());
    if (mode == QLatin1String("--compile")) {
        printf("COMPILED: %s\n", qPrintable(args.at(2)));
        return 0;
    }

    QObject *object = component.create();
    if (!object)
        return reportErrors(component.errors()) | 1;
    return app.exec();
}
