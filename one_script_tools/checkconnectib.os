﻿#Использовать v8runner
#Использовать cmdline

Перем СЕРВЕР;
Перем СЕРВЕР_ПОРТ;
Перем БАЗА;
Перем ЭТО_ФАЙЛОВАЯ_БАЗА;
Перем ПОЛЬЗОВАТЕЛЬ;
Перем ПАРОЛЬ;
Перем ПЛАТФОРМА_ВЕРСИЯ;
Перем ФАЙЛ_ЗАГРУЗКИ;

Перем Конфигуратор;
Перем Лог;

Функция Инициализация()

    Парсер = Новый ПарсерАргументовКоманднойСтроки();
    Парсер.ДобавитьИменованныйПараметр("-platform");
    Парсер.ДобавитьИменованныйПараметр("-server");
    Парсер.ДобавитьИменованныйПараметр("-base");
    Парсер.ДобавитьИменованныйПараметр("-dtpath");
    Парсер.ДобавитьИменованныйПараметр("-user");
    Парсер.ДобавитьИменованныйПараметр("-passw");

    Параметры = Парсер.Разобрать(АргументыКоманднойСтроки);
    
    ПЛАТФОРМА_ВЕРСИЯ  = Параметры["-platform"];//"8.3.10.2639"; // если пустая строка, то будет взята последняя версия
    СЕРВЕР            =  Параметры["-server"];
    СЕРВЕР_ПОРТ       = 1541; // 1541 - по умолчанию
    БАЗА              = Параметры["-base"];
    ЭТО_ФАЙЛОВАЯ_БАЗА = Не ЗначениеЗаполнено(СЕРВЕР);
    ФАЙЛ_ЗАГРУЗКИ     = Параметры["-dtpath"];
    ПОЛЬЗОВАТЕЛЬ      = Параметры["-user"];
    ПАРОЛЬ            = Параметры["-passw"];
    
    ПЛАТФОРМА_ВЕРСИЯ  = "8.3.18.1208";
    //СЕРВЕР            = "devadapter";
    //СЕРВЕР_ПОРТ       = 1541; // 1541 - по умолчанию
    //БАЗА              = "custom_rkudakov_mywork_adapter";
    //ЭТО_ФАЙЛОВАЯ_БАЗА = Не ЗначениеЗаполнено(СЕРВЕР);
    //ПОЛЬЗОВАТЕЛЬ      = "Administrator";
    //ПАРОЛЬ            = "111";
    //ФАЙЛ_ЗАГРУЗКИ    = "\\172.16.50.38\share\Kudakov\backups\adapter.dt";

    Конфигуратор = Новый УправлениеКонфигуратором();
    Конфигуратор.УстановитьКонтекст(СтрокаСоединенияИБ(), ПОЛЬЗОВАТЕЛЬ, ПАРОЛЬ);
    Конфигуратор.ИспользоватьВерсиюПлатформы(ПЛАТФОРМА_ВЕРСИЯ);

    Лог = Логирование.ПолучитьЛог("loadDt");
    ЛОГ.УстановитьУровень(УровниЛога.Отладка);

    ЛОГ.Отладка("СЕРВЕР = " + СЕРВЕР);
    ЛОГ.Отладка("БАЗА = " + БАЗА);
    ЛОГ.Отладка("ФАЙЛ_ЗАГРУЗКИ = " + ФАЙЛ_ЗАГРУЗКИ);
    ЛОГ.Отладка("ПЛАТФОРМА_ВЕРСИЯ = " + ПЛАТФОРМА_ВЕРСИЯ);
	
	
	Конфигуратор.ОтключитьсяОтХранилища();
    
КонецФункции

Функция ЗагрузитьБазуИзФайла()

    Конфигуратор.ЗагрузитьИнформационнуюБазу(ФАЙЛ_ЗАГРУЗКИ);


КонецФункции

Функция СтрокаСоединенияИБ() 
    Если ЭТО_ФАЙЛОВАЯ_БАЗА Тогда
        Возврат "/F" + БАЗА; 
    Иначе   
        Возврат "/IBConnectionString""Srvr=" + СЕРВЕР + ?(ЗначениеЗаполнено(СЕРВЕР_ПОРТ),":" + СЕРВЕР_ПОРТ,"") + ";Ref='"+ БАЗА + "'""";
    КонецЕсли;
КонецФункции

Инициализация();

Лог.Информация("Loading dt %1 for infobase %2", БАЗА);
