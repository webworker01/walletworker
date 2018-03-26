@echo off
setlocal enabledelayedexpansion
rem *UNRELATED* https://github.com/firehol/netdata/wiki

rem WalletWorker 0.1a for Komodo
rem Inspired by DeckerSU's dexscripts.win32

rem load config.ini variables
for /F "tokens=*" %%I in (config.ini) do set %%I

title=WalletWorker 0.1a - https://webworker.sh

:checkdirs
    if not exist "bin" mkdir bin
    if not exist "tmp" mkdir tmp

:checkupdates
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/', 'tmp\newpage.html')"
    if not exist "tmp\newpage.html" (
        echo Error checking for updates, continue with existing version?
        goto end
    )
    if exist "tmp\oldpage.html" (
        set newupdate=1 & fc tmp\newpage.html tmp\oldpage.html>nul && set newupdate=
    )
    move /Y tmp\newpage.html tmp\oldpage.html > nul

:getupdates
    if defined newupdate (
        echo Updating, please wait...
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/komodo-cli.exe', 'bin\komodo-cli.exe')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/komodo-tx.exe', 'bin\komodo-tx.exe')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/komodod.exe', 'bin\komodod.exe')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libcrypto-1_1.dll', 'bin\libcrypto-1_1.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libcurl-4.dll', 'bin\libcurl-4.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libcurl.dll', 'bin\libcurl.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libgcc_s_sjlj-1.dll', 'bin\libgcc_s_sjlj-1.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libnanomsg.dll', 'bin\libnanomsg.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libssl-1_1.dll', 'bin\libssl-1_1.dll')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/libwinpthread-1.dll', 'bin\libwinpthread-1.dll')"
    ) else (
        echo No updates, continuing
    )
    goto mainmenu

:menuheader
    cls
    echo WalletWorker 0.1a - [32mhttps://webworker.sh[0m
    echo ----------------------------------------
    echo.
    goto:eof

:mainmenu
    call:menuheader
    echo [[32ms[0m] - Start komodod.exe KMD
    echo [[32ma[0m] - Asset Chains menu
    echo [[32mv[0m] - VOTE2018 menu
    echo.
    echo [[94m1[0m] - KMD Get Info (komodod must be started/synced)
    echo [[94m2[0m] - KMD List Addresses
    echo [[94m3[0m] - KMD List Transactions (last 10)
    echo.
    echo [[33mx[0m] - Exit WalletWorker
    echo [[31mX[0m] - Exit WalletWorker and stop all services
    echo.
    rem SET /P M=Choose an option and then press [Enter]: 
    choice /CS /C xXs123va /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 goto end2
    if %choice% equ 2 goto end
    if %choice% equ 3 goto startkomodod
    if %choice% equ 4 goto kmdgetinfo
    if %choice% equ 5 goto kmdlistaddresses
    if %choice% equ 6 goto kmdlisttransactions
    if %choice% equ 7 goto votemenu
    if %choice% equ 8 goto acmenu
    goto end

:startkomodod
    if not defined datadir (
        start "[KMD] komodod.exe" bin\komodod -printtoconsole
    ) else (
        start "[KMD] komodod.exe" bin\komodod -printtoconsole -datadir=%datadir%
    )
    echo.
    echo Starting komodod.exe for [KMD]
    echo.
    echo Before running any other commands the blockchain must be syncing
    echo Check in komodod.exe window for lines starting with "UpdateTip"
    echo.
    echo In Get Info check that "blocks" = "longestchain" to verify fully synced
    echo.
    pause
    goto mainmenu

:kmdgetinfo
    if not defined datadir (
        bin\komodo-cli getinfo 
    ) else (
        bin\komodo-cli -datadir=%datadir% getinfo
    )
    pause
    goto mainmenu

:kmdlistaddresses
    if not defined datadir (
        bin\komodo-cli listreceivedbyaddress 1 true |more
    ) else (
        bin\komodo-cli -datadir=%datadir% listreceivedbyaddress 1 true |more
    )
    pause
    goto mainmenu

:kmdlisttransactions
    if not defined datadir (
        bin\komodo-cli listtransactions |more
    ) else (
        bin\komodo-cli -datadir=%datadir% listtransactions |more
    )
    pause
    goto mainmenu

:acmenu
    call:menuheader
    for /F "tokens=1,2" %%a in (acs.txt) do (
        set thisacid=%%a
        set thisacname=%%b
        set firstletter=!thisacname:~0,1!
        echo [[32m!thisacid![0m] - !thisacname!
    )
    set /P chosenacid=Choose by [[32mid[0m] then press [Enter]: 
    echo.
    echo %chosenacid% was chosen

    for /f "tokens=2" %%a in ('
        findstr /b /r /i /c:"%chosenacid% " "acs.txt"
    ') do (
        set chosenac=%%a
    )

    echo %chosenac% was chosen

    pause
    goto mainmenu

:votemenu
    call:menuheader
    echo [s] - Start komodod.exe VOTE2018
    echo.
    echo [1] - VOTE2018 Get Info
    echo [2] - VOTE2018 List Addresses
    echo [3] - VOTE2018 List Transactions (last 10)
    echo.
    echo [x] - Return to Main Menu
    choice /CS /C xs123 /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 goto mainmenu
    if %choice% equ 2 goto votekomodod
    if %choice% equ 3 goto votegetinfo
    if %choice% equ 4 goto votelistaddresses
    if %choice% equ 5 goto votelisttransactions
    goto mainmenu

:votekomodod
    if not defined datadir (
        start "[VOTE2018] komodod.exe" bin\komodod -printtoconsole -ac_name=VOTE2018 -ac_supply=600000000
    ) else (
        start "[VOTE2018] komodod.exe" bin\komodod -printtoconsole -datadir=%datadir%\VOTE2018 -ac_name=VOTE2018 -ac_supply=600000000
    )
    echo.
    echo Starting komodod.exe for [VOTE2018]
    echo.
    echo Before running any other commands the blockchain must be syncing
    echo Check in komodod.exe window for lines starting with "UpdateTip"
    echo.
    echo In Get Info check that "blocks" = "longestchain" to verify fully synced
    echo.
    pause
    goto votemenu

:votegetinfo
    if not defined datadir (
        bin\komodo-cli -ac_name=VOTE2018 getinfo
    ) else (
        bin\komodo-cli -datadir=%datadir%\VOTE2018 -ac_name=VOTE2018 getinfo
    )
    pause
    goto votemenu

:votelistaddresses
    if not defined datadir (
        bin\komodo-cli -ac_name=VOTE2018 listreceivedbyaddress 1 true |more
    ) else (
        bin\komodo-cli -datadir=%datadir%\VOTE2018 -ac_name=VOTE2018 listreceivedbyaddress 1 true |more
    )
    pause
    goto votemenu

:votelisttransactions
    if not defined datadir (
        bin\komodo-cli -ac_name=VOTE2018 listtransactions |more
    ) else (
        bin\komodo-cli -datadir=%datadir%\VOTE2018 -ac_name=VOTE2018 listtransactions |more
    )
    pause
    goto votemenu

:error
    echo There was a problem
    goto end2

:end
    echo Shutting down services...
    taskkill /T /IM komodod.exe 

:end2
    echo.
    echo Good bye!
    endlocal