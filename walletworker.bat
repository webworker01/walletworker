@echo off
setlocal enabledelayedexpansion
rem *UNRELATED* https://github.com/firehol/netdata/wiki

rem WalletWorker 0.0.1a for Komodo
rem Inspired by DeckerSU's dexscripts.win32

rem @todo do the part for a fresh komodo installation
rem @todo handle unable to check for updates
rem @todo validate send to address format is correct
rem @todo I think need to detect R address vs Z address and possibly use different methods to send (where the balances are coming from might make a difference too)
rem @todo gracefully shutdown komodo stop (komodo-cli stop [-ac_name=??])
rem @todo encrypt/decrypt wallet.dat with passphrase (verify/write up some msgs about incompatibility with agama)
rem @todo backup wallet (to desktop or documents?)
rem @todo add learning mode
rem @todo get live list of assetchains

:startup
    for /F "tokens=*" %%I in (config.ini) do set %%I
    title=WalletWorker 0.0.1a for Komodo - https://webworker.sh/notary
    call:checkdirs
    call:checkupdates
    call:getupdates
    goto kmdswitch

REM bat files are finicky this is way up here so it doesn't accidently get run if a section below fails
:kill
    echo Shutting down services...
    taskkill /T /IM komodod.exe
    goto end

:help
    call:menuheader
    echo [31m^^^^[0mPay attention to the line above the menus indicating which chain you currently have selected[31m^^^^[0m
    echo.
    echo Menus are mostly case sensitive, so pay attention to the commands displayed in square brackets []
    echo.
    echo This wallet currently depends on downloading the full blockchain for KMD or an assetchain.
    echo.
    echo SPV(electrum) is not currently supported, and might never be. Please use Agama wallet if you require this functionality
    echo.
    echo When you start komodod for a given chain, you must wait for the blocks that you already had downloaded to be reverified and the block chain started syncing before any of the other commands will function.  You will see lines starting with "UpdateTip" when syncing has started.
    echo.
    echo Developed on Win10x64 although Windows 7 *should* be supported
    echo.
    pause
    goto mainmenu

:webworker
    start "" https://webworker.sh/notary
    goto mainmenu

:strlen <stringVar> <resultVar> (   
    set "s=!%~1!#"
    set "len=0"
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
        if "!s:~%%P,1!" NEQ "" ( 
            set /a "len+=%%P"
            set "s=!s:~%%P!"
        )
    )
) (
    set "%~2=%len%"
)

:trim <stringVar> (
    set "s=!%~1!"
    for /f "tokens=* delims= " %%a in ("%s%") do set input=%%a
    for /l %%a in (1,1,100) do if "!input:~-1!"==" " set input=!input:~0,-1!
    set "%~1=%input%"
)

:checkdirs
    if not exist "bin" mkdir bin
    if not exist "tmp" mkdir tmp
    goto:eof

:checkupdates
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/', 'tmp\newpage.html')"
    if not exist "tmp\newpage.html" (
        echo Error checking for updates 
        rem continue with existing version?
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
    rem cls
    echo.
    echo.
    echo WalletWorker 0.0.1a - [32mhttps://webworker.sh/notary[0m
    echo ----------------------------------------
    echo.
    echo Currently on [[94m[43m%walletlabel%[0m] Chain
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

    echo [[32ms[0m] - Start komodod.exe for [[94m[43m%walletlabel%[0m]
    echo [[32ma[0m] - Asset Chains menu

    if defined chosenac (
        echo [[32mk[0m] - Switch back to KMD
    )

    echo.
    echo [[94m1[0m] - Get Info (komodod must be started/synced)
    echo [[94m2[0m] - List Addresses
    echo [[94m3[0m] - List Transactions (last 10)
    echo [[94m4[0m] - Send Funds
    echo [[94m5[0m] - New Address
    echo [[94m6[0m] - New Z Address
    echo.
    echo [[32mh[0m] - Help
    echo [[32mw[0m] - Visit website
    echo.
    echo [[33mx[0m] - Exit WalletWorker
    echo [[31mX[0m] - Exit WalletWorker and stop all services
    echo.
    rem SET /P M=Choose an option and then press [Enter]: 
    choice /CS /C xXs123vak456hw /N /M "Choose an option: "
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
    if %choice% equ 10 goto sendtoaddress
    if %choice% equ 11 goto getnewaddress
    if %choice% equ 12 goto zgetnewaddress
    if %choice% equ 13 goto help
    if %choice% equ 14 goto webworker
    goto end

:acmenu
    call:menuheader
    for /F "tokens=1,2" %%a in (acs.txt) do (
        set thisacid=%%a
        set thisacname=%%b
        set firstletter=!thisacname:~0,1!
        echo [[32m!thisacid![0m] - !thisacname!
    )
    echo.
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
    rem bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listreceivedbyaddress 1 true |more
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getaddressesbyaccount "" |more
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_listaddresses |more
    pause
    goto mainmenu

:listtransactions
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listtransactions |more
    pause
    goto mainmenu

:sendtoaddress
    echo.
    echo [31mWarning^^![0m Validation of entries here is tricky and still a work in progress!
    echo Please check and double check that you are using the values you wish to use^^!
    echo.

    set /P thisfromaddress=Enter the address with funds you wish to send from: 

    call :trim thisfromaddress
    call :strlen thisfromaddress thisfromaddresslen

    if %thisfromaddresslen% equ 0 (
        echo No from address entered.
        pause
        goto mainmenu
    )

    set thisfromaddressfirstletter=%thisfromaddress:~0,1%

    set thisfromaddressvalid=
    if /I %thisfromaddressfirstletter% equ R (
        if %thisfromaddresslen% equ 34 set thisfromaddressvalid=1
    )

    if /I %thisfromaddressfirstletter% equ Z (
        if %thisfromaddresslen% equ 95 set thisfromaddressvalid=1
    )

    if not defined thisfromaddressvalid (
        echo The send from address %thisfromaddress% you entered is invalid, please double check.
        pause
        goto mainmenu
    )

    set /P thistoaddress=Enter the address to send to: 
    call :trim thistoaddress
    call :strlen thistoaddress thistoaddresslen
    if %thistoaddresslen% equ 0 (
        echo No to address entered.
        pause
        goto mainmenu
    )

    set thistoaddressfirstletter=%thistoaddress:~0,1%

    set thistoaddressvalid=
    if /I %thistoaddressfirstletter% equ R (
        if %thistoaddresslen% equ 34 set thistoaddressvalid=1
    )

    if /I %thistoaddressfirstletter% equ Z (
        if %thistoaddresslen% equ 95 set thistoaddressvalid=1
    )

    if not defined thistoaddressvalid (
        echo The send to address %thistoaddress% you entered is invalid, please double check.
        pause
        goto mainmenu
    )

    set /P thisamount=Enter the amount to send: 
    echo %thisamount%|findstr /xr "[.]*[0-9][.]*[0-9]* 0" >nul && (
        echo.
    ) || (
        set thistoaddress=
        set thistoamount=
        echo %thisamount% is not a valid amount, please double check.
        pause
        goto mainmenu
    )    

    set /P verifiedsend=Are you sure you want to send %thisamount% %walletlabel% to %thistoaddress%? [Y/N]: 
    if /I %verifiedsend% equ Y (
        echo sending...
        bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_sendmany "%thisfromaddress%" "[{\"address\": \"%thistoaddress%\", \"amount\": %thisamount%}]"
        pause
    )
    set thistoaddress=
    set thistoamount=
    goto mainmenu

:zgetnewaddress
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_getnewaddress
    pause
    goto mainmenu

:error
    echo There was a problem
    goto end

:end
    echo.
    echo Good bye!
    endlocal