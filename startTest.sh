#!/bin/bash
#***
#
#@Author: 
#	UlizkoIM@intech.rshb.ru
#
#***

#разные цвета для вывода на консоль
echoincolor () {
    case $1 in
        "red") tput setaf 1;;
        "green") tput setaf 2;;
        "orange") tput setaf 3;;
        "blue") tput setaf 4;;
        "purple") tput setaf 5;;
        "gray" | "grey") tput setaf 7;;
    esac
    echo "$2";
    tput sgr0
}

#имя скрипта jmx
testName=$1

#получение количества сэмплеров в скрипте jmx
sampler_count=$( grep -E -o 'testclass="HTTPSamplerProxy" testname="[0-9]+' $testName | wc -l )

#проверка параметра Time Unit, должен стоять в seconds
isUnitS=$( grep -P -o "(?<=name=\"Unit\"\>)[S|M](?=\<\/stringProp)" $testName )

#функция округления дробных чисел
round() {
	local num=$1
	printf "%.0f" "$num"
}

#читаем ввод данных от нагрузочника
read -p "Введите интенсивность в RPS: " TaregtRate
read -p "Введите длительность ступени в секундах: " StepDuration
read -p "Введите уровень нагрузки в RPS за одну ступень: " RampupStepsCount
read -p "Только для тестов Подтверждения и Стабильности - иначе 0. Введите длительность теста в секундах после выхода на плато: " HoldTargetRateTime

#считаем поля Taregt Rate, Ramp-up Steps Count, Ramp-up Time, Hold Target Rate Time.
P_TargetRate=$(round $(( ( TaregtRate + (sampler_count - 1) ) / sampler_count )))

P_StepDuration=$(round $StepDuration)

P_RampupStepsCount=$(round $(( P_TargetRate / ( RampupStepsCount / sampler_count ) )))

P_RampupTime=$(round $(( P_RampupStepsCount * P_StepDuration )))

P_HoldTargetRateTime=$(round $HoldTargetRateTime)

#выводим предупреждение о некорректных настройках в Time Unit
if [ "$isUnitS" == "M" ]
    then
    echo ""
    echoincolor red "*** ПРОВЕРЬТЕ НАСТРОЙКИ В Arrivals Thread Group. Параметр Time Unit сейчас в значении minutes, а должен быть в seconds ***"
    sleep 5
    echo ""
fi

echo ""
echoincolor purple "********** Arrivals Thread Group будет сконфигурирован следующим образом **********"
echo ""
echoincolor green " Интенсивность в RPS [Target Rate (arrivals/sec)] = $P_TargetRate"
echoincolor green " Длительность теста поиска Максимума [Ramp-up Time (sec)] = $P_RampupTime"
echoincolor green " Количество ступеней [Ramp-up Steps Count] = $P_RampupStepsCount"
echoincolor green " Длительность теста для Подтверждения или Стабильности [Hold Target Rate Time (sec)] = $P_HoldTargetRateTime"
echo ""
echoincolor purple "*************************************************************************************"
echo ""
sleep 2

#запускаем тест с рассчитанными параметрами
JVM_ARGS="-Xms512m -Xmx4096m" /u01/jmeter2/bin/Scripts/Scripts_Ulizko/apache-jmeter-5.4.3/bin/jmeter.sh -JP_TargetRate=$P_TargetRate -JP_RampupTime=$P_RampupTime -JP_RampupStepsCount=$P_RampupStepsCount -JP_HoldTargetRateTime=$P_HoldTargetRateTime -n -t $testName
