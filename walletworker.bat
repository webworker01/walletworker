@echo off
setlocal enabledelayedexpansion
rem *UNRELATED* https://github.com/firehol/netdata/wiki

rem WalletWorker 0.0.1a for Komodo
rem @author webworker01 <https://webworker.sh>

rem Inspired by DeckerSU's dexscripts.win32

rem @todo even better shutdown handling (save or detect state of currently running komodods)
rem @todo better options/handling for daemon windows (e.g. option to not show daemon window at all)
rem @todo get live list of assetchains
rem @todo collect interest
rem @todo encrypt/decrypt wallet.dat with passphrase (verify/write up some msgs about incompatibility with agama)
rem @todo add learning mode
rem @todo add self update for this file
rem @todo reduce update to once daily
rem @todo add check for update option
rem @todo handle unable to check for updates

goto startup

REM bat files are finicky.. this is way up here so it doesn't accidently get run if a section below fails
:kill
    echo Shutting down services...
    bin\komodo-cli -datadir=%configdir% stop
    for /f "tokens=2" %%a in (acs.txt) do (
        if defined datadir (
            set kmdkilldatadir=-datadir=%configdir%\%%a
        ) else (
            set kmdkilldatadir=
        )

        if exist "%configdir%\%%a" (
            bin\komodo-cli !kmdkilldatadir! -ac_name=%%a stop
        )
    )
    rem kill em all
    rem taskkill /T /IM komodod.exe
    goto end

:killone
    echo Shutting down %walletlabel%...
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% stop
    goto mainmenu

:help
    call :menuheader
    echo [31m^^^^[0mPay attention to the line above the menus indicating which chain you currently have selected[31m^^^^[0m
    echo.
    echo Menus are mostly case sensitive, so pay attention to the commands displayed in square brackets []
    echo.
    echo This wallet currently depends on downloading the full blockchain for KMD or an assetchain.
    echo.
    echo SPV(electrum) is not currently supported, and might never be. Please use Agama wallet if you require this functionality
    echo.
    echo When you start komodod for a given chain, you must wait for the blocks that you already had downloaded to be reverified 
    echo and the block chain started syncing before any of the other commands will function.  
    echo.
    echo You will see lines starting with "UpdateTip" when syncing has started.
    echo.
    echo Developed on Win10x64 although Windows 7 *should* be supported
    echo.
    echo If you found this program useful, please star it on https://github.com/webworker01/walletworker and 
    echo vote for me as a notary node to support future projects.
    echo.
    pause
    goto mainmenu

:startup
    title=WalletWorker 0.0.1a for Komodo - https://webworker.sh/notary
    mode con:cols=150 lines=40
    if exist "config.ini" (
        for /F "tokens=*" %%I in (config.ini) do set %%I
    ) else (
        goto setupconfig
    )
    goto setup

:setup
    call :checkdirs
    call :checkzcash
    call :checkkomodo
    call :checkupdates
    call :getupdates
    goto kmdswitch

:setupconfig
    cls
    echo.
    echo =[ WalletWorker for Komodo - Quick Setup ]=
    echo.
    echo WalletWorker is a working but experimental product. By proceeding, you acknowledge that you have read,
    echo understood and agree to the conditions of the included LICENSE file in its entirety.  
    echo.
    echo In particular, you understand that there is no warranty and agree to the limitations of liability as
    echo detailed in sections 15 and 16 of the LICENSE.
    echo.

    choice /N /M "Do you agree with the above statement? [Y/N] "
    SET licenseagree=%ERRORLEVEL%
    if %licenseagree% equ 2 goto end
    echo licenseagree=yes> config.ini

    echo.
    echo You can choose a custom data directory here if you wish. Make sure it is a valid path^^!
    echo If you mess this up, delete config.ini and start over.
    echo.
    set /P inputdatadir=Enter a custom data directory or Enter for default [%APPDATA%\Komodo]: 
    call :trim inputdatadir

    if "%inputdatadir%" neq "" (
        echo datadir=%inputdatadir%>> config.ini
        set datadir=%inputdatadir%
    )

    echo.
    choice /N /M "Would you like to show komodod logs in the daemon windows? [Y/N] "
    SET loggingchoice=%ERRORLEVEL%
    if %loggingchoice% equ 1 (
        echo logtoscreen=yes>> config.ini
        set logtoscreen=yes
    )
    if %loggingchoice% equ 2 (
        echo logtoscreen=no>> config.ini
        set logtoscreen=no
    )
    goto setup

:checkdirs
    if defined datadir (
        if not exist "%datadir%" mkdir %datadir%
        set configdir=%datadir%
    ) else (
        if not exist "%APPDATA%\Komodo" mkdir "%APPDATA%\Komodo"
        set configdir=%APPDATA%\Komodo
    )
    if not exist "%APPDATA%\ZcashParams" mkdir "%APPDATA%\ZcashParams"
    if not exist "bin" mkdir bin
    if not exist "tmp" mkdir tmp
    goto:eof

:checkzcash
    if not exist "%APPDATA%\ZcashParams\sprout-proving.key" (
        cls
        echo.
        echo Download ZcashParams, please wait ... it's about 900MB be patient
        echo.
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://z.cash/downloads/sprout-proving.key', '%APPDATA%\ZcashParams\sprout-proving.key')"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://z.cash/downloads/sprout-verifying.key', '%APPDATA%\ZcashParams\sprout-verifying.key')"
    )
    goto:eof

:checkkomodo
    if not exist "%configdir%\komodo.conf" (
        copy komodo.conf %configdir%\komodo.conf
        call :genrandom randomone
        echo rpcuser=user!randomone!>> %configdir%\komodo.conf
        call :genrandom randomtwo
        echo rpcpassword=!randomtwo!>> %configdir%\komodo.conf
    )
    goto:eof

:checkupdates
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://artifacts.supernet.org/latest/windows/', 'tmp\newpage.html')"
    if not exist "tmp\newpage.html" (
        echo Error checking for updates 
        rem continue with existing version?
    )
    if exist "tmp\oldpage.html" (
        set newupdate=1 & fc tmp\newpage.html tmp\oldpage.html>nul && set newupdate=
    ) else (
        set newupdate=1
    )
    move /Y tmp\newpage.html tmp\oldpage.html > nul
    goto:eof

:getupdates
    if defined newupdate (
        echo New updates were found for komodod. Please make sure any existing komodod.exe instances are fully closed before continuing.
        pause
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
    echo.
    echo WalletWorker 0.0.1a - [32mhttps://webworker.sh/notary[0m
    echo ----------------------------------------
    echo.
    echo Currently on [[94m[43m%walletlabel%[0m] Chain in %configdir%
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
        set kmdparamdatadir=-datadir=%datadir% -exportdir=%datadir%
    ) else (
        set kmdparamdatadir=-exportdir=%APPDATA%\Komodo
    )
    goto mainmenu

:mainmenu
    call :menuheader

    echo [[32ms[0m] - Start komodod.exe for [[94m[43m%walletlabel%[0m]
    echo [[32ma[0m] - Asset Chains menu

    if defined chosenac (
        echo [[32mk[0m] - Switch back to KMD
    )

    echo.
    echo Options in blue require komodod to be started and synced
    echo [[94m1[0m] - Get Balance
    echo [[94m2[0m] - Get Info
    echo [[94m3[0m] - List Addresses
    echo [[94m4[0m] - List Transactions (last 10)
    echo [[94m5[0m] - Send Funds
    echo [[94m6[0m] - New Address
    echo [[94m7[0m] - Private Keys Menu
    echo.

    echo [[94mb[0m] - Backup wallet.dat
    if not defined chosenac (
        REM echo [[94mi[0m] - Collect Interest
    )
    echo [[94mz[0m] - Check Private transaction results
    echo.

    echo [[32mh[0m] - Help
    echo [[32mw[0m] - My notary node proposal
    echo.
    echo [[33mx[0m] - Exit WalletWorker
    echo [[31mX[0m] - Exit WalletWorker and stop all services
    echo [[31mc[0m] - Stop komodod.exe for [%walletlabel%]
    echo.
    choice /CS /C sak1234567hwxXizbc /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 goto startkomodod
    if %choice% equ 2 goto acmenu
    if %choice% equ 3 goto kmdswitch
    if %choice% equ 4 goto getbalance
    if %choice% equ 5 goto getinfo
    if %choice% equ 6 goto listaddresses
    if %choice% equ 7 goto listtransactions
    if %choice% equ 8 goto sendtoaddress
    if %choice% equ 9 goto getnewaddress
    if %choice% equ 10 goto privkeymenu
    if %choice% equ 11 goto help
    if %choice% equ 12 goto webworker
    if %choice% equ 13 goto end
    if %choice% equ 14 goto kill
    if %choice% equ 15 goto collectinterest
    if %choice% equ 16 goto zresults
    if %choice% equ 17 goto backupwallet
    if %choice% equ 18 goto killone
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
            set kmdparamdatadir=-datadir=%configdir%\%chosenac% -exportdir=%configdir%
        ) else (
            set kmdparamdatadir=-exportdir=%configdir%
        )
    ) else (
        echo [id] not found
        pause
    )
    goto mainmenu

:startkomodod
    if "%logtoscreen%" equ "yes" (
        set printtoconsole=-printtoconsole
    )

    if defined chosenac (
        if not exist %configdir%\%chosenac% mkdir %configdir%\%chosenac%
    )

    start "[%walletlabel%] komodod.exe" bin\komodod %printtoconsole% %kmdparamdatadir% %kmdparamacname% %kmdparamacsupply%
    echo.
    echo Starting komodod.exe for [%walletlabel%]
    echo.
    echo A new window was opened for [%walletlabel%], you can minimize this or leave it up, 
    echo but do not close it if you wish to do anything with it.
    echo.
    if "%logtoscreen%" equ "yes" (
        echo If you don't want to see all the log messages in that window you can change logtoscreen=no in config.ini
    ) else (
        echo If you want to see all the log messages in that window you can change logtoscreen=yes in config.ini
    )
    echo.
    echo Before running any other commands the blockchain must be syncing
    echo Check in komodod.exe window for lines starting with "UpdateTip"
    echo.
    echo Then choose Get Info and check that "blocks" = "longestchain" to verify fully synced
    echo.
    pause
    goto mainmenu

:collectinterest
    echo You found a hidden option, neat^^! But it's not implemented yet sorry.
    pause
    goto mainmenu

:backupwallet
    call :menuheader
    set exportprefix=wallet
    set exportmethod=backupwallet
    goto exportdata

:exportdata
    call :datestr

    if not defined chosenac (
        set exportfilename=%exportprefix%KMD%datestr%
    ) else (
        set exportfilename=%exportprefix%%chosenac%%datestr%
    )

    echo We will now backup your %exportprefix% to the directory you choose as %exportfilename%
    echo.
    echo [[94m1[0m] - %USERPROFILE%\Documents
    echo [[94m2[0m] - %USERPROFILE%\Desktop
    echo [[94m3[0m] - %configdir%
    echo.
    echo [[33mx[0m] - Return to Main Menu
    echo.
    choice /C 123x /N /M "Choose a directory: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 4 goto mainmenu
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% %exportmethod% %exportfilename%
    if %choice% equ 1 move %configdir%\%exportfilename% %USERPROFILE%\Documents\
    if %choice% equ 2 move %configdir%\%exportfilename% %USERPROFILE%\Desktop\
    pause
    goto mainmenu

:getbalance
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getbalance
    pause
    goto mainmenu

:getinfo
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getinfo
    pause
    goto mainmenu

:getnewaddress
    call :menuheader
    echo [[94m1[0m] - New Transparent R Address
    echo [[94m2[0m] - New Private Z Address
    echo.
    echo [[33mx[0m] - Return to Main Menu
    echo.
    choice /CS /C 12x /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getnewaddress
    if %choice% equ 2 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_getnewaddress
    if %choice% equ 3 goto mainmenu
    pause
    goto mainmenu

:listaddresses
    call :menuheader
    echo [[94m1[0m] - GetAddressesByAccount
    echo [[94m2[0m] - ListReceivedByAddress
    echo [[94m3[0m] - ListAddressGroupings
    echo [[94m4[0m] - Z_ListAddresses
    echo.
    echo [[33mx[0m] - Return to Main Menu
    echo.
    choice /CS /C 1234x /N /M "Choose an option: "
    SET choice=%ERRORLEVEL%
    if %choice% equ 1 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% getaddressesbyaccount "" |more
    if %choice% equ 2 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listreceivedbyaddress 1 true |more
    if %choice% equ 3 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listaddressgroupings |more
    if %choice% equ 4 bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_listaddresses |more
    if %choice% equ 5 goto mainmenu
    pause
    goto mainmenu

:listtransactions
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% listtransactions |more
    pause
    goto mainmenu

:privkeymenu
    call :menuheader
    set thisprivkey=

    echo [[94m1[0m] - Import key for R Address
    echo [[94m2[0m] - Import key for Z Address
    echo [[94m3[0m] - Export key for R Address
    echo [[94m4[0m] - Export key for Z Address
    echo [[94m5[0m] - Dump wallet (as txt file)
    echo.
    echo [[33mx[0m] - Return to Main Menu
    echo.
    choice /CS /C 12345x /N /M "Choose an option: "
    echo.
    SET choice=%ERRORLEVEL%

    if %choice% equ 1 (
        set privkeymethod=importprivkey
        goto importprivkey
    )
    if %choice% equ 2 (
        set privkeymethod=z_importkey
        goto importprivkey
    )
    if %choice% equ 3 (
        set privkeymethod=dumpprivkey
        goto dumpprivkey
    )
    if %choice% equ 4 (
        set privkeymethod=z_exportkey
        goto dumpprivkey
    )
    if %choice% equ 5 (
        set exportprefix=keys
        set exportmethod=z_exportwallet
        goto exportdata
    )
    if %choice% equ 6 goto mainmenu
    goto mainmenu

:dumpprivkey
    set thisaddress=
    set /P thisaddress=Enter the address: 
    call :trim thisaddress
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% %privkeymethod% %thisaddress%
    pause
    goto mainmenu

:importprivkey
    set thisprivkey=
    set /P thisprivkey=Enter the private key: 
    call :trim thisprivkey
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% %privkeymethod% %thisaddress%
    pause
    goto mainmenu

:sendfromaddress
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
    goto:eof

:sendcheckprivaddresses
    set thisprivtransvalid=
    if /I %thistoaddressfirstletter% equ Z set thisprivtransvalid=1
    if /I %thisfromaddressfirstletter% equ Z set thisprivtransvalid=1

    if not defined thisprivtransvalid (
        echo Sorry one of your addresses must be a Z address for a Private transaction. Please use Transparent transaction.
        pause
        goto mainmenu
    )
    goto:eof

:sendtoaddress
    set thistranstype=1
    set thistranstrans=
    set thisprivtrans=
    set thisfromaddress=
    set thistoaddress=
    set thisamount=

    echo.
    echo [31mWarning^^![0m Validation of entries here is tricky and still a work in progress^^!
    echo While there are some safeguards already put in place, you are using this feature at your own risk^^!
    echo If you receive any output that looks out of place, you can always type CTRL-C to abort the bat file^^!
    echo Please check and double check that you are using the values you wish to use^^!
    echo.
    echo Do you wish to send a [T]ransparent or [P]rivate transaction?
    choice /C TP /N /M "Choose an option: "
    SET thistranstype=%ERRORLEVEL%
    if %thistranstype% equ 1 set thistranstrans=1
    if %thistranstype% equ 2 set thisprivtrans=1

    if %thistranstype% equ 1 (
        echo.
        echo Setting up a Transparent transaction
        echo Note: This will attempt to use any available funds in your wallet
        echo.
    )

    if %thistranstype% equ 2 (
        echo.
        echo Setting up a Private transaction
        echo Note: You will need to specify the address which has funds you wish to use
        echo At least one of the 2 addresses must be a Z address
        echo.

        call :sendfromaddress
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

    if %thistranstype% equ 2 (
        call :sendcheckprivaddresses
    )

    set /P thisamount=Enter the amount to send: 
    echo %thisamount%|findstr /xr "[.]*[0-9][.]*[0-9]* 0" >nul && (
        echo.
    ) || (
        echo %thisamount% is not a valid amount, please double check.
        pause
        goto mainmenu
    )    

    set /P verifiedsend=Are you sure you want to send %thisamount% %walletlabel% to %thistoaddress%? [Y/N]: 
    if /I %verifiedsend% equ Y (
        echo sending...
        if %thistranstype% equ 1 (
            bin\komodo-cli %kmdparamdatadir% %kmdparamacname% sendtoaddress "%thistoaddress%" %thisamount%
        )

        if %thistranstype% equ 2 (
            bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_sendmany "%thisfromaddress%" "[{\"address\": \"%thistoaddress%\", \"amount\": %thisamount%}]"
            bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_getoperationresult
        )
        pause
    )
    goto mainmenu

:webworker
    start "" https://webworker.sh/notary
    goto mainmenu

:zresults
    bin\komodo-cli %kmdparamdatadir% %kmdparamacname% z_getoperationresult
    pause
    goto mainmenu

:datestr 
    for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
        set month=%%j
        set day=%%k
        set year=%%l
    )
    for /f "tokens=1-4 delims=: " %%m in ("%time%") do (
        set hour=%%m
        set minute=%%n
    )
    set datestr=%year%%month%%day%%hour%%minute%
    goto:eof

rem @link https://superuser.com/a/571136
:genrandom <resultVar> (
    set alfanum=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
    set pwd=
    for /l %%b IN (0, 1, 32) DO (
        set /a rnd_num=!RANDOM! * 62 / 32768 + 1
        for /f %%c in ('echo %%alfanum:~!rnd_num!^,1%%') do set pwd=!pwd!%%c
    )
    set "%~1=%pwd%"
    goto:eof
)

rem @link https://stackoverflow.com/a/5841587/5016797
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
    goto:eof
)

rem @link https://stackoverflow.com/a/3002207/5016797
:trim <stringVar> (
    set "s=!%~1!"
    for /f "tokens=* delims= " %%a in ("%s%") do set input=%%a
    for /l %%a in (1,1,100) do if "!input:~-1!"==" " set input=!input:~0,-1!
    set "%~1=%input%"
    goto:eof
)

:error
    echo There was a problem^^!
    goto end

:end
    echo.
    echo Goodbye^^!
    endlocal
