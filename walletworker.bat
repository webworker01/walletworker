@echo off
setlocal enabledelayedexpansion
rem *UNRELATED* https://github.com/firehol/netdata/wiki

rem WalletWorker 0.0.1a for Komodo
rem Inspired by DeckerSU's dexscripts.win32

rem load config.ini variables
for /F "tokens=*" %%I in (config.ini) do set %%I

title=WalletWorker 0.0.1a - https://webworker.sh

:startup
    call:checkdirs
    call:checkupdates
    call:getupdates
    goto kmdswitch

REM bat files are finicky this is way up here so it doesn't accidently get run if a section below fails
:kill
    echo Shutting down services...
    taskkill /T /IM komodod.exe
    goto end

:checkdirs
    if not exist "bin" mkdir bin
    if not exist "tmp" mkdir tmp
    goto:eof

:checkupdates
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/', 'tmp\newpage.html')"
    if not exist "tmp\newpage.html" (
        echo Error checking for updates, continue with existing version?
        rem @todo handle updates not found
    )
    if exist "tmp\oldpage.html" (
        set newupdate=1 & fc tmp\newpage.html tmp\oldpage.html>nul && set newupdate=
    )
    move /Y tmp\newpage.html tmp\oldpage.html > nul
    goto:eof

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
    goto:eof

:menuheader
    cls
    echo WalletWorker 0.1a - [32mhttps://webworker.sh[0m
    echo ----------------------------------------
    echo.
    goto:eof

:kmdswitch
    set chosenacid=
    set chosenac=
    set chosenacsupply=
    set walletlabel=KMD
    set kmdparamacname=
    set kmdparamacsupply=
    if defined datadir (
        set kmdparamdatadir=-datadir=%datadir%
    )
    goto mainmenu

:mainmenu
    call:menuheader

    echo [[32ms[0m] - Start komodod.exe [[94m[43m%walletlabel%[0m]
    echo [[32ma[0m] - Asset Chains menu

    if defined chosenac (
        echo [[32mk[0m] - Switch back to KMD
    )

    echo.
    echo [[94m1[0m] - %walletlabel% Get Info (komodod must be started/synced)
    echo [[94m2[0m] - %walletlabel% List Addresses
    echo [[94m3[0m] - %walletlabel% List Transactions (last 10)
    echo.
    echo [[33mx[0m] - Exit WalletWorker
    echo [[31mX[0m] - Exit WalletWorker and stop all services
    echo.
    rem SET /P M=Choose an option and then press [Enter]: 
    choice /CS /C xXs123vak /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 goto end
    if %choice% equ 2 goto kill
    if %choice% equ 3 goto startkomodod
    if %choice% equ 4 goto getinfo
    if %choice% equ 5 goto listaddresses
    if %choice% equ 6 goto listtransactions
    if %choice% equ 7 goto votemenu
    if %choice% equ 8 goto acmenu
    if %choice% equ 9 goto kmdswitch
    goto end

:acmenu
    call:menuheader
    for /F "tokens=1,2" %%a in (acs.txt) do (
        set thisacid=%%a
        set thisacname=%%b
        set firstletter=!thisacname:~0,1!
        echo [[32m!thisacid![0m] - !thisacname!
    )
    set /P chosenacid=Choose by [[32mid[0m] then press [Enter]: 
    set foundmatch=
    for /f "tokens=2,3" %%a in ('
        findstr /b /r /i /c:"%chosenacid% " "acs.txt"
    ') do (
        set chosenac=%%a
        set chosenacsupply=%%b
        set foundmatch=1
    )

    if defined foundmatch (
        set walletlabel=%chosenac%
        set kmdparamacname=-ac_name=%chosenac%
        set kmdparamacsupply=-ac_supply=%chosenacsupply%
        if defined datadir (
            set kmdparamdatadir=-datadir=%datadir%\%chosenac%
        )
    ) else (
        echo [id] not found
        pause
    )

    goto mainmenu

:startkomodod
    start "[%walletlabel%] komodod.exe" bin\komodod -printtoconsole %kmdparamdatadir% %kmdparamacname% %kmdparamacsupply%

    echo.
    echo Starting komodod.exe for [%walletlabel%]
    echo.
    echo Before running any other commands the blockchain must be syncing
    echo Check in komodod.exe window for lines starting with "UpdateTip"
    echo.
    echo Then in choose Get Info and check that "blocks" = "longestchain" to verify fully synced
    echo.
    pause
    goto mainmenu

:getnewaddress
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getnewaddress
    pause
    goto mainmenu

:getinfo
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getinfo
    pause
    goto mainmenu

:listaddresses
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listreceivedbyaddress 1 true |more
    pause
    goto mainmenu

:listtransactions
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listtransactions |more
    pause
    goto mainmenu

:error
    echo There was a problem
    goto end

:end
    echo.
    echo Good bye!
    endlocal