@echo off
:: get date and time.
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%-%MM%-%DD%"
set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
echo datestamp: "%datestamp%"
echo timestamp: "%timestamp%"
echo fullstamp: "%fullstamp%"

:: get computer name.
for /f "skip=1 delims=" %%A in (
  'wmic computersystem get name'
) do for /f "delims=" %%B in ("%%A") do set "compName=%%A"
echo Computer Name: %CompName%
set CompName=%CompName: =%

:: get desktop folder
SETLOCAL
FOR /F "usebackq" %%f IN (`PowerShell -NoProfile -Command "Write-Host([Environment]::GetFolderPath('Desktop'))"`) DO (
  SET "DESKTOP_FOLDER=%%f"
  )
@ECHO %DESKTOP_FOLDER%

:: set report directory
set "DirName=BuildReview_%CompName%_%datestamp%"
set "ReportName=Report_%timestamp%"
cd %DESKTOP_FOLDER%
if exist %DESKTOP_FOLDER%\%DirName% (
    echo Folder %DESKTOP_FOLDER%\%DirName% already exists, skipping creation.
) else (
	mkdir %DESKTOP_FOLDER%\%DirName%
	)
cd %DirName%
:: check for time travel and exit if true.
if exist %ReportName% (
    echo Report %ReportName% already exists exiting with status code "time travel".
	EXIT [/B]
) else (
	mkdir %ReportName%
	cd %ReportName%
	)
echo Storing reports in %DESKTOP_FOLDER%\%DirName%\%ReportName%
echo.
::call :runTests 2> %fullstamp%_errors.log

::EXIT [/B]

:::runTests
:: run info gathering
echo ~^*~ Starting OS tests ~^*~
echo Gathering System Information...
systeminfo > SystemInfo.txt
echo Capturing Patch Status...
wmic qfe list > Windows-Patches.txt
echo Gathering software versions...
wmic /output: "Software.txt" product get Name, Version, Vendor
echo Enumerating running processes...
wmic process list > Processes.txt
echo Exporting stored credentials...
cmdkey /list > Stored-Credentials.txt
echo.

echo ~^*~ Starting network tests ~^*~
echo Capturing network interfaces...
ipconfig /all > IPConfig.txt
echo Ping check www.google.com
PING www.google.com > InternetAccess.txt
echo Capturing default routes...
route print > Route.txt
echo Tracing route to google.com
tracert google.com > Traceroute.txt
echo Exporting ARP cache...
arp -A > ARP-Known-Hosts.txt
echo Enumerating listening ports...
netstat -ano > Listening-Ports.txt
echo Capturing hosts file...
type C:\WINDOWS\System32\drivers\etc\hosts > Etc_host-file-content.txt
echo Exporting DNS records...
ipconfig /displaydns | findstr "Record" | findstr "Name Host" > DNS-Records.txt
echo Capturing sessions...
klist sessions > List-Sessions.txt
echo Enumerating shares...
net share > Shares.txt
echo.

echo ~^*~ Starting local user tests ~^*~ 
echo Enumerating local groups...
net localgroup > Local-Groups.txt
echo Enumerating local users...
net users > Local-Users.txt
echo Enumerating accounts...
net accounts > Local-PW-Policies.txt
echo Capturing logged in users...
qwinsta > List-Loggedin-Users.txt
echo.

echo ~^*~ Starting domain tests ~^*~
echo Exporting Group Policy...
GPResult /R > GP-Result.txt	
echo Exporting domain password policy...
net accounts /domain > Domain-PW-Policy.txt
echo Enumerating domain users...
net users /domain > Domain-Users.txt
echo Enumerating domain groups...
net groups /domain > Domain-Groups.txt
echo.
echo Finishing tests and exiting.