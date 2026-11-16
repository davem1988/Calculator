# Custom Calculator setup window.
# electron-builder prepends its header (plugins, languages, command-line flags)
# and still embeds the packaged app. This file replaces the default wizard.
# A custom script does not get the separate uninstaller build, so the
# uninstaller is written during install.

!ifdef ONE_CLICK
  !error "build/installer.nsi expects the assisted installer. Set nsis.oneClick to false."
!endif

Var newStartMenuLink
Var oldStartMenuLink
Var newDesktopLink
Var oldDesktopLink
Var oldShortcutName
Var oldMenuDirectory
Var appExe
Var launchLink
Var setupRoot

!define MUI_ABORTWARNING

!include "common.nsh"
!include "MUI2.nsh"
!include "multiUser.nsh"
!include "${BUILD_RESOURCES_DIR}\allowOnlyOneInstallerInstance.nsh"
!include "StrContains.nsh"
!include "LogicLib.nsh"

ShowUninstDetails nevershow
RequestExecutionLevel user

!macro initMultiUser
  !ifdef INSTALL_MODE_PER_ALL_USERS
    !insertmacro setInstallModePerAllUsers
  !else
    ${If} ${UAC_IsInnerInstance}
    ${AndIfNot} ${UAC_IsAdmin}
      SetErrorLevel 0x666666
      Quit
    ${endIf}

    !ifndef MULTIUSER_INIT_TEXT_ADMINREQUIRED
      !define MULTIUSER_INIT_TEXT_ADMINREQUIRED "$(^Caption) requires administrator privileges."
    !endif
    !ifndef MULTIUSER_INIT_TEXT_POWERREQUIRED
      !define MULTIUSER_INIT_TEXT_POWERREQUIRED "$(^Caption) requires at least Power User privileges."
    !endif
    !ifndef MULTIUSER_INIT_TEXT_ALLUSERSNOTPOSSIBLE
      !define MULTIUSER_INIT_TEXT_ALLUSERSNOTPOSSIBLE "Your user account does not have sufficient privileges to install $(^Name) for all users of this computer."
    !endif

    StrCpy $hasPerMachineInstallation "0"
    StrCpy $hasPerUserInstallation "0"

    ReadRegStr $perMachineInstallationFolder HKLM "${INSTALL_REGISTRY_KEY}" InstallLocation
    ${if} $perMachineInstallationFolder != ""
      StrCpy $hasPerMachineInstallation "1"
    ${endif}

    ReadRegStr $perUserInstallationFolder HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation
    ${if} $perUserInstallationFolder != ""
      StrCpy $hasPerUserInstallation "1"
    ${endif}

    ${GetParameters} $R0
    ${GetOptions} $R0 "/allusers" $R1
    ${IfNot} ${Errors}
      StrCpy $hasPerMachineInstallation "1"
      StrCpy $hasPerUserInstallation "0"
    ${EndIf}

    ${GetOptions} $R0 "/currentuser" $R1
    ${IfNot} ${Errors}
      StrCpy $hasPerMachineInstallation "0"
      StrCpy $hasPerUserInstallation "1"
    ${EndIf}

    ${if} $hasPerUserInstallation == "1"
    ${andif} $hasPerMachineInstallation == "0"
      !insertmacro setInstallModePerUser
    ${elseif} $hasPerUserInstallation == "0"
      ${andif} $hasPerMachineInstallation == "1"
      !insertmacro setInstallModePerAllUsers
    ${else}
      !ifdef INSTALL_MODE_PER_ALL_USERS_DEFAULT
        !insertmacro setInstallModePerAllUsers
      !else
        !insertmacro setInstallModePerUser
      !endif
    ${endif}
  !endif
!macroend

!macro ensureInstallDir
  !ifdef allowToChangeInstallationDirectory
    ${StrContains} $0 "${APP_FILENAME}" "$INSTDIR"
    ${If} $0 == ""
      StrCpy $INSTDIR "$INSTDIR\${APP_FILENAME}"
    ${EndIf}
  !endif
!macroend

!macro installCalculatorFiles
  !ifdef APP_BUILD_DIR
    File /r "${APP_BUILD_DIR}\*.*"
  !else
    ${if} $installMode == "all"
      SetShellVarContext current
    ${endif}
    !insertmacro copyFile "$EXEPATH" "$LOCALAPPDATA\${APP_INSTALLER_STORE_FILE}"
    ${if} $installMode == "all"
      SetShellVarContext all
    ${endif}
  !endif

  WriteUninstaller "$INSTDIR\${UNINSTALL_FILENAME}"
!macroend

!include "installUtil.nsh"
!include "installer.nsh"

Function ExtractToOutDir
  InitPluginsDir
  !insertmacro extractEmbeddedAppPackage
FunctionEnd

Function OpenSetupUi
  HideWindow
  ; Keep the setup app outside $PLUGINSDIR. NSIS deletes that folder on exit.
  StrCpy $setupRoot "$TEMP\CalculatorSetup"
  CreateDirectory "$setupRoot\app"
  SetOutPath "$setupRoot\app"
  Call ExtractToOutDir

  FileOpen $R8 "$setupRoot\install-dir.txt" w
  FileWrite $R8 "$INSTDIR"
  FileClose $R8
  FileOpen $R8 "$setupRoot\installer-path.txt" w
  FileWrite $R8 "$EXEPATH"
  FileClose $R8

  StrCpy $1 '"$setupRoot\app\${APP_EXECUTABLE_FILENAME}" --setup-ui --payload="$setupRoot"'
  Exec $1
  SetErrorLevel 0
  Quit
FunctionEnd

!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro addLangs

!ifmacrodef customHeader
  !insertmacro customHeader
!endif

Function LaunchInstalledApp
  HideWindow
  !insertmacro StartApp
FunctionEnd

Function .onInit
  ${IfNot} ${Silent}
    HideWindow
  ${EndIf}

  Call setInstallSectionSpaceRequired
  SetOutPath $INSTDIR
  ${LogSet} on

  !ifmacrodef preInit
    !insertmacro preInit
  !endif

  !ifdef DISPLAY_LANG_SELECTOR
    !insertmacro MUI_LANGDLL_DISPLAY
  !endif

  !insertmacro check64BitAndSetRegView

  ${IfNot} ${UAC_IsInnerInstance}
    !insertmacro ALLOW_ONLY_ONE_INSTALLER_INSTANCE
  ${EndIf}

  !insertmacro initMultiUser

  !ifmacrodef customInit
    !insertmacro customInit
  !endif

  !ifmacrodef addLicenseFiles
    InitPluginsDir
    !insertmacro addLicenseFiles
  !endif

  ${IfNot} ${Silent}
  ${AndIfNot} ${UAC_IsInnerInstance}
    Call OpenSetupUi
  ${EndIf}
FunctionEnd

Section "install" INSTALL_SECTION_ID
  !ifndef INSTALL_MODE_PER_ALL_USERS
    ${if} $hasPerMachineInstallation == "1"
    ${andIf} ${Silent}
      ${ifNot} ${UAC_IsAdmin}
        ShowWindow $HWNDPARENT ${SW_HIDE}
        !insertmacro UAC_RunElevated
        ${Switch} $0
          ${Case} 0
            ${Break}
          ${Case} 1223
            ${Break}
          ${Default}
            MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to elevate, error $0" /SD IDOK
            ${Break}
        ${EndSwitch}
        Quit
      ${else}
        !insertmacro setInstallModePerAllUsers
      ${endIf}
    ${endIf}
  !endif

  !insertmacro ensureInstallDir

  InitPluginsDir
  ${IfNot} ${Silent}
    SetDetailsPrint none
  ${endif}

  StrCpy $appExe "$INSTDIR\${APP_EXECUTABLE_FILENAME}"
  !insertmacro setLinkVars

  ${ifNot} ${UAC_IsInnerInstance}
    !insertmacro CHECK_APP_RUNNING
  ${endif}

  Var /GLOBAL keepShortcuts
  StrCpy $keepShortcuts "false"
  !insertmacro setIsTryToKeepShortcuts
  ${if} $isTryToKeepShortcuts == "true"
    ReadRegStr $R1 SHELL_CONTEXT "${INSTALL_REGISTRY_KEY}" KeepShortcuts
    ${if} $R1 == "true"
    ${andIf} ${FileExists} "$appExe"
      StrCpy $keepShortcuts "true"
    ${endIf}
  ${endif}

  !insertmacro uninstallOldVersion SHELL_CONTEXT
  !insertmacro handleUninstallResult SHELL_CONTEXT

  ${if} $installMode == "all"
    !insertmacro uninstallOldVersion HKEY_CURRENT_USER
    !insertmacro handleUninstallResult HKEY_CURRENT_USER
  ${endIf}

  SetOutPath $INSTDIR
  !ifndef APP_BUILD_DIR
    Call ExtractToOutDir
  !endif

  !ifdef UNINSTALLER_ICON
    File /oname=uninstallerIcon.ico "${UNINSTALLER_ICON}"
  !endif

  !insertmacro installCalculatorFiles
  !insertmacro registryAddInstallInfo
  !insertmacro addStartMenuLink $keepShortcuts
  !insertmacro addDesktopLink $keepShortcuts

  ${if} ${FileExists} "$newStartMenuLink"
    StrCpy $launchLink "$newStartMenuLink"
  ${else}
    StrCpy $launchLink "$INSTDIR\${APP_EXECUTABLE_FILENAME}"
  ${endIf}

  !ifmacrodef registerFileAssociations
    !insertmacro registerFileAssociations
  !endif

  !ifmacrodef customInstall
    !insertmacro customInstall
  !endif

  ${if} ${Silent}
  ${andIf} ${isForceRun}
    Call LaunchInstalledApp
  ${endIf}
SectionEnd

Function setInstallSectionSpaceRequired
  !insertmacro setSpaceRequired ${INSTALL_SECTION_ID}
FunctionEnd

# The process-info helper picks un._GetProcessInfo only while this is set.
# It is defined after the install section so the installer itself still
# calls _GetProcessInfo.
!define BUILD_UNINSTALLER
Function un._GetProcessInfo
  !insertmacro FUNC_GETPROCESSINFO
FunctionEnd

!include "uninstaller.nsh"
