﻿'#########################################################
'#  frmProjectProperties.bas                             #
'#  This file is part of VisualFBEditor                  #
'#  Authors: Xusinboy Bekchanov (2018-2019)              #
'#########################################################

#include once "mff/Form.bi"
#include once "mff/TabControl.bi"
#include once "mff/CommandButton.bi"
#include once "mff/Label.bi"
#include once "mff/ComboBoxEdit.bi"
#include once "mff/TextBox.bi"
#include once "mff/GroupBox.bi"
#include once "mff/Panel.bi"
#include once "mff/CheckBox.bi"
#include once "mff/ImageBox.bi"
#include once "mff/ListControl.bi"
#include once "mff/Picture.bi"
#include once "mff/RadioButton.bi"
#include once "mff/Dictionary.bi"
#include once "mff/TreeView.bi"

Using My.Sys.Forms

'#Region "Form"
	Type frmProjectProperties Extends Form
		Declare Static Sub cmdOK_Click(ByRef Sender As Control)
		Declare Static Sub cmdCancel_Click(ByRef Sender As Control)
		Declare Static Sub pnlApplication_Click(ByRef Sender As Control)
		Declare Static Sub tpCompile_Click(ByRef Sender As Control)
		Declare Static Sub lstType_Change(ByRef Sender As ListControl)
		Declare Static Sub txtValue_LostFocus(ByRef Sender As TextBox)
		Declare Sub RefreshProperties()
		Declare Static Sub cmdAdvancedOptions_Click(ByRef Sender As Control)
		Declare Constructor
		
		Dim As TabControl tabProperties
		Dim As TabPage tpGeneral, tpMake, tpCompile, tpDebugging
		Dim As CommandButton cmdOK, cmdCancel, cmdHelp, cmdAdvancedOptions
		Dim As Label lblProjectType, lblMainFile, lblProjectName, lblProjectDescription, lblCompilationArguments64, lblIcon, lblTitle, lblMajor, lblMinor, lblRevision, lblBuild, lblResourceFile, lblIconResourceFile, lblCompilationArguments32Linux, lblCompilationArguments64Linux, lblCompilationArguments32, lblType, lblValue, lblHelpFileName, lblCompilationArguments321
		Dim As Picture picCompileToGCC
		Dim As ComboBoxEdit cboProjectType, cboMainFile, cboResourceFile, cboIconResourceFile, cboOptimizationLevel
		Dim As TextBox txtProjectName, txtProjectDescription, txtCompilationArguments32Windows, txtCompilationArguments64Windows, txtIcon, txtTitle, txtMajor, txtMinor, txtRevision, txtBuild, txtCompilationArguments32Linux, txtValue, txtHelpFileName, txtCommandLineArguments, txtCompilationArguments32Windows1, txtCompilationArguments64Windows1, txtCompilationArguments32Linux1, txtCompilationArguments64Linux
		Dim As GroupBox grbVersionNumber, grbApplication, grbVersionInformation, grbCompilationArguments, grbCompileToGCC
		Dim As CheckBox chkAutoIncrementVersion, chkCreateDebugInfo
		Dim As ListControl lstType
		Dim As RadioButton optCompileToGas, optCompileToGcc, optOptimizationFastCode, optOptimizationLevel, optOptimizationSmallCode, optNoOptimization
		Dim As Dictionary Types, MainFiles, ResourceFiles, IconResourceFiles
		Dim As TreeNode Ptr ProjectTreeNode
	End Type
	
	Common Shared pfProjectProperties As frmProjectProperties Ptr
'#End Region

#ifndef __USE_MAKE__
	#include once "frmProjectProperties.bas"
#endif
