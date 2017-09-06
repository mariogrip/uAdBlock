/*
 * Copyright (C) 2015 - Michael Zanetti <michael.zanetti@ubuntu.com> (from tweekgeek)
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

#include "cmd.h"
#include <iostream>
#include <QFileInfo>

using namespace std;

Cmd::Cmd(QObject *parent) :
    QObject(parent),
    m_busy(false)
{
    m_process = new QProcess(this);
    connect(m_process, SIGNAL(finished(int, QProcess::ExitStatus)), this, SLOT(processFinished(int,QProcess::ExitStatus)));
    connect(m_process, SIGNAL(errorOccurred(QProcess::ProcessError)), this, SLOT(error(QProcess::ProcessError)));
    connect(m_process, &QProcess::readyReadStandardError, this, &Cmd::readStdErr);

}

bool Cmd::busy() const
{
    return m_busy;
}

bool Cmd::getError() const
{
    return m_error;
}

void Cmd::error(QProcess::ProcessError error)
{
    cout << "ERORRO" << endl;
    m_error = true;
    m_busy = false;
    emit busyChanged();
    emit errorChanged();
}

void Cmd::SetPassword(QString& pass)
{
    m_pass = pass;
}

void Cmd::execute(const QString &cmdLine)
{
    QStringList list = cmdLine.split(" ");
    if (list.count() > 0) {
        QString program = list.takeFirst();
        m_process->start(program, list);
        m_busy = true;
        emit busyChanged();
    }
}

void Cmd::sudo(const QString &cmdLine)
{
    execute("sudo -S -p passwdprompt " + cmdLine);
}

void Cmd::processFinished(int exitCode, QProcess::ExitStatus)
{
    QByteArray data = m_process->readAll();
    m_busy = false;
    m_error = false;
    emit busyChanged();
    emit errorChanged();
    emit finished(exitCode == 0, data.data());
}

void Cmd::readStdErr()
{
    QByteArray data = m_process->readAllStandardError();
    cout << data.data() << endl;
    if (data.contains("passwdprompt")) {
            emit passwordRequested();
            return;
    }
}

void Cmd::providePassword(const QString &password)
{
    if (m_process) {
        m_process->write(password.toLatin1());
        m_process->write("\n");
        cout << "password provided" << endl;
    }
}

void Cmd::cancel()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished(1);
        cout << "cancelled" << endl;
    }
}

bool Cmd::fileExists(QString path) {
    QFileInfo check_file(path);
    return check_file.exists() && check_file.isFile();
}
