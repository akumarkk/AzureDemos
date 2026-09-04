# Wiki: Troubleshooting ODBC Error [IM002] (Data Source Name Not Found)

## Overview
- **Error Code:** `[IM002]`
- **Error Message:** `Connection failed: ERROR [IM002] [Microsoft][ODBC Driver Manager] Data source name not found and no default driver specified`
- **Cause:** The system is missing the required IBM Informix ODBC driver, or the driver architecture (32-bit vs. 64-bit) does not match the application runtime.

---

## Direct Fix: Install the Informix ODBC Driver

To resolve this issue, you must install the Informix Client SDK (CSDK) / ODBC driver that matches your application's architecture (32-bit or 64-bit).

### Step 1: Install the Informix CSDK / ODBC Driver
1. Download and extract the Informix Client SDK package (or installation archive).
2. Run the installer or extract the files to a permanent directory (e.g., `C:\InformixCSDK`).
3. Ensure the ODBC driver DLLs (`iclit09a.dll` / `iclis09a.dll`) are present in `%INFORMIXDIR%\bin`.

### Step 2: Set Environment Variables
The ODBC driver manager requires `INFORMIXDIR` to locate system libraries:
- `INFORMIXDIR` = `C:\Program Files\Informix.15.0.1.0`
- Append `%INFORMIXDIR%\bin` to the system `Path` variable.

*PowerShell Quick-Set:*
```powershell
[Environment]::SetEnvironmentVariable("INFORMIXDIR", "C:\Program Files\Informix.15.0.1.0", "Machine")
$envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("Path", "$envPath;C:\Program Files\Informix.15.0.1.0\bin", "Machine")