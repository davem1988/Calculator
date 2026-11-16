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
Var TitleFont
Var SetupDialog
Var DirEdit
Var BrowseButton
Var LaunchCheckbox
Var LaunchAfter

!define MUI_ABORTWARNING
!define MUI_CUSTOMFUNCTION_GUIINIT GuiInit
!define MUI_BGCOLOR 0F0F0F

!include "common.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "multiUser.nsh"
!include "${BUILD_RESOURCES_DIR}\allowOnlyOneInstallerInstance.nsh"
!include "StrContains.nsh"
!include "WinMessages.nsh"
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
    !insertmacro extractEmbeddedAppPackage
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

!ifmacrodef licensePage
  !insertmacro licensePage
!endif

PageEx custom
  PageCallbacks SetupPageShow SetupPageLeave
  Caption "Calculator"
PageExEnd

!insertmacro MUI_PAGE_INSTFILES

PageEx custom
  PageCallbacks FinishPageShow FinishPageLeave
  Caption "Calculator"
PageExEnd

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro addLangs

!ifmacrodef customHeader
  !insertmacro customHeader
!endif

Function GuiInit
  CreateFont $TitleFont "Segoe UI" 18 700
  Call StyleWindow
FunctionEnd

Function StyleWindow
  SetCtlColors $HWNDPARENT 0xFFFFFF 0x0F0F0F

  GetDlgItem $0 $HWNDPARENT 1028
  ${If} $0 <> 0
    ShowWindow $0 ${SW_HIDE}
  ${EndIf}
  GetDlgItem $0 $HWNDPARENT 1034
  ${If} $0 <> 0
    ShowWindow $0 ${SW_HIDE}
  ${EndIf}
  GetDlgItem $0 $HWNDPARENT 1035
  ${If} $0 <> 0
    ShowWindow $0 ${SW_HIDE}
  ${EndIf}
  GetDlgItem $0 $HWNDPARENT 1036
  ${If} $0 <> 0
    ShowWindow $0 ${SW_HIDE}
  ${EndIf}

  GetDlgItem $0 $HWNDPARENT 1037
  ${If} $0 <> 0
    SetCtlColors $0 0xD4B83E 0x0F0F0F
    SendMessage $0 ${WM_SETFONT} $TitleFont 1
  ${EndIf}
  GetDlgItem $0 $HWNDPARENT 1038
  ${If} $0 <> 0
    SetCtlColors $0 0xFFFFFF 0x0F0F0F
  ${EndIf}
FunctionEnd

Function SetupPageShow
  ${If} ${Silent}
  ${OrIf} ${isUpdated}
    Abort
  ${EndIf}

  Call StyleWindow
  !insertmacro MUI_HEADER_TEXT "Calculator" "Choose where to install"

  nsDialogs::Create 1018
  Pop $SetupDialog
  ${If} $SetupDialog == error
    Abort
  ${EndIf}
  SetCtlColors $SetupDialog 0xFFFFFF 0x0F0F0F

  ${NSD_CreateLabel} 0 0 100% 12u "Installs Calculator for your user account."
  Pop $0
  SetCtlColors $0 0xFFFFFF 0x0F0F0F

  ${NSD_CreateLabel} 0 20u 100% 12u "Folder"
  Pop $0
  SetCtlColors $0 0xD4B83E 0x0F0F0F

  !ifdef allowToChangeInstallationDirectory
    ${NSD_CreateText} 0 34u 220u 14u "$INSTDIR"
    Pop $DirEdit
    SetCtlColors $DirEdit 0xFFFFFF 0x17171A

    ${NSD_CreateButton} 226u 34u 54u 14u "Browse"
    Pop $BrowseButton
    ${NSD_OnClick} $BrowseButton OnBrowse
  !else
    ${NSD_CreateLabel} 0 34u 100% 24u "$INSTDIR"
    Pop $0
    SetCtlColors $0 0xFFFFFF 0x0F0F0F
  !endif

  ${NSD_CreateLabel} 0 58u 100% 24u "Shortcuts are added to the desktop and the Start menu."
  Pop $0
  SetCtlColors $0 0x646464 0x0F0F0F

  GetDlgItem $0 $HWNDPARENT 1
  SendMessage $0 ${WM_SETTEXT} 0 "STR:Install"
  GetDlgItem $0 $HWNDPARENT 3
  ShowWindow $0 ${SW_HIDE}

  nsDialogs::Show
FunctionEnd

Function OnBrowse
  nsDialogs::SelectFolderDialog "Install Calculator to" "$INSTDIR"
  Pop $0
  ${If} $0 != error
  ${AndIf} $0 != ""
    ${NSD_SetText} $DirEdit $0
  ${EndIf}
FunctionEnd

Function SetupPageLeave
  !ifdef allowToChangeInstallationDirectory
    ${NSD_GetText} $DirEdit $INSTDIR
    ${If} $INSTDIR == ""
      MessageBox MB_OK|MB_ICONEXCLAMATION "Choose a folder."
      Abort
    ${EndIf}
    !insertmacro ensureInstallDir
  !endif
FunctionEnd

Function FinishPageShow
  ${If} ${Silent}
    Abort
  ${EndIf}

  Call StyleWindow
  !insertmacro MUI_HEADER_TEXT "Calculator" "Finished"

  nsDialogs::Create 1018
  Pop $SetupDialog
  ${If} $SetupDialog == error
    Abort
  ${EndIf}
  SetCtlColors $SetupDialog 0xFFFFFF 0x0F0F0F

  ${NSD_CreateLabel} 0 0 100% 16u "Calculator is installed."
  Pop $0
  SetCtlColors $0 0xD4B83E 0x0F0F0F
  SendMessage $0 ${WM_SETFONT} $TitleFont 1

  ${NSD_CreateLabel} 0 22u 100% 24u "$INSTDIR"
  Pop $0
  SetCtlColors $0 0xFFFFFF 0x0F0F0F

  !ifndef HIDE_RUN_AFTER_FINISH
    ${NSD_CreateCheckbox} 0 52u 100% 14u "Launch Calculator"
    Pop $LaunchCheckbox
    ${NSD_SetState} $LaunchCheckbox ${BST_CHECKED}
    SetCtlColors $LaunchCheckbox 0xFFFFFF 0x0F0F0F
  !endif

  GetDlgItem $0 $HWNDPARENT 1
  SendMessage $0 ${WM_SETTEXT} 0 "STR:Finish"
  GetDlgItem $0 $HWNDPARENT 3
  ShowWindow $0 ${SW_HIDE}

  nsDialogs::Show
FunctionEnd

Function FinishPageLeave
  !ifndef HIDE_RUN_AFTER_FINISH
    ${NSD_GetState} $LaunchCheckbox $LaunchAfter
    ${If} $LaunchAfter == ${BST_CHECKED}
      Call LaunchInstalledApp
    ${EndIf}
  !endif
FunctionEnd

Function LaunchInstalledApp
  HideWindow
  !insertmacro StartApp
FunctionEnd

Function .onInit
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
FunctionEnd

!include "installUtil.nsh"
!include "installer.nsh"

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
