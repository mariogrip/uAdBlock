/*
 * Copyright (C) 2015 - Michael Zanetti <michael.zanetti@ubuntu.com>
 *               2017 - Marius Gripsgard <marius@ubports.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CMD_H
#define CMD_H

#include <QObject>
#include <QProcess>

class Cmd : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit Cmd(QObject *parent = 0);

    bool busy() const;

signals:
    void busyChanged();
    void finished(bool success, const QString &stdout);

    void passwordRequested();

public slots:
    void execute(const QString &cmdLine);
    void sudo(const QString &cmdLine);
    void SetPassword(QString &pass);

    void providePassword(const QString &password);
    void cancel();
    bool fileExists(QString);

private slots:
    void processFinished(int exitCode, QProcess::ExitStatus);
    void readStdErr();
    void readStd(int exitCode, QProcess::ExitStatus);

private:
    QProcess *m_process;
    bool m_busy;
    QString m_pass;

};

#endif // CMD_H
