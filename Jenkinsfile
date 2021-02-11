@Library("check_backup")
import io.libs.SqlUtils
import io.libs.ProjectHelpers
import io.libs.Utils

def sqlUtils = new SqlUtils()
def utils = new Utils()
def projectHelpers = new ProjectHelpers()
def backupTasks = [:]
def restoreTasks = [:]
def dropDbTasks = [:]
def createDbTasks = [:]
def runHandlers1cTasks = [:]
def updateDbTasks = [:]
def var_steps = [14]
pipeline {

    parameters {

        string(defaultValue: "${env.jenkinsAgent}", description: 'Нода дженкинса, на которой запускать пайплайн. По умолчанию master', name: 'jenkinsAgent')
        string(defaultValue: "${env.server1c}", description: 'Имя сервера 1с, по умолчанию localhost', name: 'server1c')
        string(defaultValue: "${env.server1cPort}", description: 'Порт рабочего сервера 1с. По умолчанию 1540. Не путать с портом агента кластера (1541)', name: 'server1cPort')
        string(defaultValue: "${env.agent1cPort}", description: 'Порт агента кластера 1с. По умолчанию 1541', name: 'agent1cPort')
        string(defaultValue: "${env.platform1c}", description: 'Версия платформы 1с, например 8.3.12.1685. По умолчанию будет использована последня версия среди установленных', name: 'platform1c')
        string(defaultValue: "${env.serverSql}", description: 'Имя сервера MS SQL. По умолчанию localhost', name: 'serverSql')
        string(defaultValue: "${env.admin1cUser}", description: 'Имя администратора с правом открытия вншних обработок (!) для базы тестирования 1с Должен быть одинаковым для всех баз', name: 'admin1cUser')
        string(defaultValue: "${env.admin1cPwd}", description: 'Пароль администратора базы тестирования 1C. Должен быть одинаковым для всех баз', name: 'admin1cPwd')
        string(defaultValue: "${env.sqlUser}", description: 'Имя администратора сервера MS SQL. Если пустой, то используется доменная  авторизация', name: 'sqlUser')
        string(defaultValue: "${env.sqlPwd}", description: 'Пароль администратора MS SQL.  Если пустой, то используется доменная  авторизация', name: 'sqlPwd')
        string(defaultValue: "${env.templatebases}", description: 'Список баз для тестирования через запятую. Например work_erp,work_upp', name: 'templatebases')
        string(defaultValue: "${env.storages1cPath}", description: 'Необязательный. Пути к хранилищам 1С для обновления копий баз тестирования через запятую. Число хранилищ (если указаны), должно соответствовать числу баз тестирования. Например D:/temp/storage1c/erp,D:/temp/storage1c/upp', name: 'storages1cPath')
        string(defaultValue: "${env.storageUser}", description: 'Необязательный. Администратор хранилищ  1C. Должен быть одинаковым для всех хранилищ', name: 'storageUser')
        string(defaultValue: "${env.storagePwd}", description: 'Необязательный. Пароль администратора хранилищ 1c', name: 'storagePwd')
    }


    agent {
        label "${(env.jenkinsAgent == null || env.jenkinsAgent == 'null') ? "master" : env.jenkinsAgent}"
    }
    options {
        timeout(time: 8, unit: 'HOURS') 
        buildDiscarder(logRotator(numToKeepStr:'10'))
    }
    stages {
        stage("Подготовка") {
            steps {
                timestamps {
                    script {

                    notifyStarted();
                        templatebasesList = utils.lineToArray(templatebases.toLowerCase())
                        storages1cPathList = utils.lineToArray(storages1cPath.toLowerCase())

                        if (storages1cPathList.size() != 0) {
                            assert storages1cPathList.size() == templatebasesList.size()
                        }

                        server1c = server1c.isEmpty() ? "localhost" : server1c
                        serverSql = serverSql.isEmpty() ? "localhost" : serverSql
                        server1cPort = server1cPort.isEmpty() ? "1540" : server1cPort
                        agent1cPort = agent1cPort.isEmpty() ? "1541" : agent1cPort
                        env.sqlUser = sqlUser.isEmpty() ? "sa" : sqlUser
                        testbase = null

                        // создаем пустые каталоги
                        dir ('build') {
                            writeFile file:'dummy', text:''
                        }
                    }
                }
            }
        }
        stage("Запуск") {
            steps {
                timestamps {
                    script {

                        for (i = 0;  i < templatebasesList.size(); i++) {
                             for (j = 0;  j < var_steps.size(); j++) {
                            templateDb = templatebasesList[i]
                            storage1cPath = storages1cPathList[j]
                            testbase = "test_${templateDb}"
                            testbaseConnString = projectHelpers.getConnString(server1c, testbase, agent1cPort)
                            backupPath = "${env.WORKSPACE}/build/temp_${templateDb}_${utils.currentDateStamp()}"
                            day = var_steps[j]
                            // 1. Удаляем тестовую базу из кластера (если он там была) и очищаем клиентский кеш 1с
                            timestamps {
                                       stage("Удаление ${testbase}") {
                                           projectHelpers = new ProjectHelpers()
                                           utils = new Utils()

                                           projectHelpers.dropDb(server1c, server1cPort, serverSql, testbase, admin1cUser, admin1cPwd, sqluser, sqlPwd)
                                       }
                                   }

                            // 3. Загружаем sql бекап эталонной базы в тестовую
                          stage("Востановление ${testbase} бекапа ${day}") {
                                      timestamps {
                                          sqlUtils = new SqlUtils()
                                          utils = new Utils()
                                          date = utils.currentDateStampminusday(day)
                                          sqlUtils.createEmptyDb(serverSql, testbase, sqlUser, sqlPwd)
                                          sqlUtils.restoreDb(serverSql, testbase, templateDb, sqlUser, sqlPwd,date)
                                      }
                                  }

                            // 4. Создаем тестовую базу кластере 1С
                           stage("Создание базы ${testbase}") {
                                       timestamps {
                                            projectHelpers = new ProjectHelpers()
                                           try {
                                               projectHelpers.createDb(platform1c, server1c, serversql, testbase, null, false)
                                           } catch (excp) {
                                               echo "Error happened when creating base ${testbase}. Probably base already exists in the ibases.v8i list. Skip the error"
                                           }
                                       }
                                   }
                            // 5. Обновляем тестовую базу из хранилища 1С (если применимо)

                        stage("Тестирование базы ${testbase}") {
                                  timestamps {
                                    if (templatebasesList.size() == 0) {
                                                                      return
                                                                  }

                                                                  platform1cLine = ""
                                                                  if (platform1c != null && !platform1c.isEmpty()) {
                                                                      platform1cLine = "--v8version ${platform1c}"
                                                                  }

                                                                  admin1cUsrLine = ""
                                                                  if (admin1cUser != null && !admin1cUser.isEmpty()) {
                                                                      admin1cUsrLine = "-user ${admin1cUser}"
                                                                  }

                                                                  admin1cPwdLine = ""
                                                                  if (admin1cPwd != null && !admin1cPwd.isEmpty()) {
                                                                      admin1cPwdLine = "-passw ${admin1cPwd}"
                                                                  }


                                                                   returnCode = utils.cmd("oscript one_script_tools/checkconnectib.os -server ${server1c} -base ${testbase} ${admin1cUsrLine} ${admin1cPwdLine}")
                                                                      if (returnCode != 0) {
                                                                      currentBuild.result = 'FAILURE'
                                                                      notifyFailed();
                                                                      return error
                                                                      } else notifySuccessful();

                                  }

                                  }


                         }   // 6. Запускаем внешнюю обработку 1С, которая очищает базу от всплывающего окна с тем, что база перемещена при старте 1С


}




                    }
                }
            }
        }

    }   
    post {
        always {
            script {
                if (currentBuild.result == "ABORTED") {
                    return
                }


                dir ('build/out/allure') {
                    writeFile file:'environment.properties', text:"Build=${env.BUILD_URL}"
                }

                allure includeProperties: false, jdk: '', results: [[path: 'build/out/allure']]
            }
        }
    }
}


def notifyStarted() {
  // send to Slack

  // send to email
  emailext (
      subject: "Запущена: задача ${env.JOB_NAME} ${templatebases}",
      body: "Запущена: задача ${env.JOB_NAME} [${env.BUILD_NUMBER}] баз ${templatebases}: Ход работы можно посмотреть: ${env.BUILD_URL}",
      to: '$DEFAULT_RECIPIENTS',
    )
}


def notifyFailed() {


  emailext (
      subject: "ОШИБКА: задача ${env.JOB_NAME} ${templatebases}",
      body: "Ошибка: задача ${env.JOB_NAME} [${env.BUILD_NUMBER}] баз ${templatebases}: Ход работы можно посмотреть: ${env.BUILD_URL}",
       to: '$DEFAULT_RECIPIENTS',
    )
}

def notifySuccessful() {


  emailext (
      subject: "Выполнено: задача ${env.JOB_NAME} ${templatebases}",
      body: "Выполнено: задача ${env.JOB_NAME} [${env.BUILD_NUMBER}] баз ${templatebases}: Ход работы можно посмотреть: ${env.BUILD_URL}",
       to: '$DEFAULT_RECIPIENTS',
    )
}


def dropDbTask(server1c, server1cPort, serverSql, infobase, admin1cUser, admin1cPwd, sqluser, sqlPwd) {
    return {
        timestamps {
            stage("Удаление ${infobase}") {
                def projectHelpers = new ProjectHelpers()
                def utils = new Utils()

                projectHelpers.dropDb(server1c, server1cPort, serverSql, infobase, admin1cUser, admin1cPwd, sqluser, sqlPwd)
            }
        }
    }
}

def createDbTask(server1c, serverSql, platform1c, infobase) {
    return {
        stage("Создание базы ${infobase}") {
            timestamps {
                def projectHelpers = new ProjectHelpers()
                try {
                    projectHelpers.createDb(platform1c, server1c, serversql, infobase, null, false)
                } catch (excp) {
                    echo "Error happened when creating base ${infobase}. Probably base already exists in the ibases.v8i list. Skip the error"
                }
            }
        }
    }
}

def backupTask(serverSql, infobase, backupPath, sqlUser, sqlPwd) {
    return {
        stage("sql бекап ${infobase}") {
            timestamps {
                def sqlUtils = new SqlUtils()

                sqlUtils.checkDb(serverSql, infobase, sqlUser, sqlPwd)
                sqlUtils.backupDb(serverSql, infobase, backupPath, sqlUser, sqlPwd)
            }
        }
    }
}

def restoreTask(serverSql, infobase, backupPath, sqlUser, sqlPwd,day) {
    return {
        stage("Востановление ${infobase} бекапа ${day}") {
            timestamps {
                sqlUtils = new SqlUtils()
                utils = new Utils()
                date = utils.currentDateStampminusday(day)
                sqlUtils.createEmptyDb(serverSql, infobase, sqlUser, sqlPwd)
                sqlUtils.restoreDb(serverSql, infobase, backupPath, sqlUser, sqlPwd,date)
            }
        }
    }
}

def runHandlers1cTask(infobase, admin1cUser, admin1cPwd, testbaseConnString) {
    return {
        stage("Запуск 1с обработки на ${infobase}") {
            timestamps {
                def projectHelpers = new ProjectHelpers()
                projectHelpers.unlocking1cBase(testbaseConnString, admin1cUser, admin1cPwd)
            }
        }
    }
}

def updateDbTask(platform1c, infobase, storage1cPath, storageUser, storagePwd, connString, admin1cUser, admin1cPwd) {
    return {
        stage("Загрузка из хранилища ${infobase}") {
            timestamps {
                prHelpers = new ProjectHelpers()

                if (storage1cPath == null || storage1cPath.isEmpty()) {
                    return
                }

                prHelpers.loadCfgFrom1CStorage(storage1cPath, storageUser, storagePwd, connString, admin1cUser, admin1cPwd, platform1c)
                prHelpers.updateInfobase(connString, admin1cUser, admin1cPwd, platform1c)
            }
        }
    }
}
