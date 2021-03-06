﻿/'
Designer.bi
Authors: Nastase Eodor, Xusinboy Bekchanov
Based On:
Simple Designer. Educational purposes.
(c)2013 Nastase Eodor
nastasa.eodor@gmail.com
http://rqwork.xhost.ro
Updated And added cross-platform
by Xusinboy Bekchanov (2018-2019)
bxusinboy@mail.ru
'/

#include once "Designer.bi"

#ifdef __USE_GTK__
	#define CtrlHandle GtkWindow Ptr
#else
	#define CtrlHandle HWND
#endif

Dim Shared mnuDesigner As PopupMenu

Namespace My.Sys.Forms
	#ifdef __USE_GTK__
		Function Designer.GetControl(ControlHandle As GtkWidget Ptr) As Any Ptr
			'Return Cast(Any Ptr, GetWindowLongPtr(CtrlHandle, GWLP_USERDATA))
			Return SelectedControl
		End Function
	#else
		Function Designer.GetControl(ControlHandle As HWND) As Any Ptr
			Return Cast(Any Ptr, GetWindowLongPtr(ControlHandle, GWLP_USERDATA))
		End Function
	#endif
	
	'Operator Designer.Cast As Control Ptr
	'   Return @This
	'End Operator
	
	Sub Designer.ProcessMessage(ByRef message As Message)
		
		'message.Result = -1    
		
	End Sub
	
	'Sub Designer.HandleIsAllocated(BYREF Sender As Control)
	'    With QDesigner(@Sender)
	'        .CreateDots(GetParent(Sender.Handle))
	'        .Dialog = Sender.Handle
	'            'dim as RECT R
	'            'GetClientRect(Sender.Handle, @R)
	'            'if .FShowGrid then
	'              '.DrawGrid(GetDC(Sender.Handle), R)
	'            'else
	'              'FillRect(GetDC(Sender.Handle), @R, cast(HBRUSH, 16))
	'            'end if 
	'    End With
	'End Sub
	
	#ifndef __USE_GTK__    
		Function Designer.EnumChildsProc(hDlg As HWND, lParam As LPARAM) As Boolean
			If lParam Then
				With *Cast(WindowList Ptr, lParam)
					.Count = .Count + 1
					.Child = Reallocate(.Child, .Count * SizeOf(HWND))
					.Child[.Count-1] = hDlg
				End With
			End If
			Return True
		End Function
	#endif
	
	#ifndef __USE_GTK__
		Sub Designer.GetChilds(Parent As HWND = 0)
			FChilds.Count = 0
			FChilds.Child = CAllocate(0)
			EnumChildWindows(IIf(Parent, Parent, FDialog), Cast(WNDENUMPROC, @EnumChildsProc), CInt(@FChilds))
		End Sub
	#endif
	
	#ifndef __USE_GTK__
		Sub Designer.ClipCursor(hDlg As HWND)
			Dim As RECT R
			If IsWindow(hDlg) Then
				GetClientRect(hDlg, @R)
				MapWindowPoints(hDlg, 0,Cast(Point Ptr, @R), 2)
				.ClipCursor(@R)
			Else
				.ClipCursor(0)
			End If
		End Sub
	#endif
	
	Sub Designer.DrawBox(R As RECT)
		#ifndef __USE_GTK__
			FHDc = GetDCEx(FDialog, 0, DCX_PARENTCLIP Or DCX_CACHE Or DCX_CLIPSIBLINGS)
			Brush = GetStockObject(NULL_BRUSH)
			PrevBrush = SelectObject(FHDc, Brush)
			SetROP2(FHDc, R2_NOT)
			Rectangle(FHDc, R.Left, R.Top, R.Right, R.Bottom)
			SelectObject(FHDc, PrevBrush)
			ReleaseDc(FDialog, FHDc)
		#endif
	End Sub
	
	Sub Designer.DrawBoxs(R() As RECT)
		'''for future implementation of multiselect suport
		For i As Integer = 0 To UBound(R)
			DrawBox(R(i))
		Next   
	End Sub
	
	Function Designer.GetClassAcceptControls(AClassName As String) As Boolean
		'''for future implementation of classbag struct
		Return False
	End Function
	
	Sub Designer.Clear
		#ifndef __USE_GTK__
			GetChilds
			For i As Integer = FChilds.Count -1 To 0 Step -1
				DestroyWindow(FChilds.Child[i])
			Next
		#endif
		HideDots
	End Sub
	
	Function Designer.ClassExists() As Boolean
		'FClass = SelectedClass
		#ifndef __USE_GTK__
			Dim As WNDCLASSEX wcls
			wcls.cbSize = SizeOf(wcls)
		#endif
		Return SelectedClass <> "" 'and (GetClassInfoEx(0, FClass, @wcls) or GetClassInfoEx(instance, FClass, @wcls))
	End Function
	
	'function Designer.GetClassName(hDlg as HWND) as string
	'dim as Wstring Ptr s
	'WReallocate s, 256
	'*s = space(255)
	'dim as integer L = .GetClassName(hDlg, s, Len(*s))
	'return trim(Left(*s, L))
	'end function   
	'
	'#IfDef __USE_GTK__
	Function Designer.ControlAt(Parent As Any Ptr, X As Integer,Y As Integer) As Any Ptr
		'#Else
		'	function Designer.ControlAt(Parent as HWND,X as integer,Y as integer) as HWND
		'#EndIf
		#ifdef __USE_GTK__
			If Parent = 0 Then Return Parent
			Dim As Integer ALeft, ATop, AWidth, AHeight
			Dim As Any Ptr Ctrl
			For i As Integer = iGet(ReadPropertyFunc(Parent, "ControlCount")) - 1 To 0 Step -1
				Ctrl = ControlByIndexFunc(Parent, i)
				If Ctrl Then
					If QBoolean(ReadPropertyFunc(Ctrl, "Visible")) Then
						ControlGetBoundsSub(Ctrl, @ALeft, @ATop, @AWidth, @AHeight)
						If (X > ALeft And X < ALeft + AWidth) And (Y > ATop And Y < ATop + AHeight) Then
							Return ControlAt(Ctrl, X - ALeft, Y - ATop)
						End If
					End If
				End If
			Next i
			Return Parent
		#else
			Dim ParentHwnd As Hwnd = *Cast(HWND Ptr, ReadPropertyFunc(Parent, "Handle"))
			Dim Result As Hwnd = ChildWindowFromPoint(ParentHwnd, Type<Point>(X, Y))
			If Result = 0 Or Result = ParentHwnd Then
				Return Parent
			Else
				Dim As Rect R
				GetWindowRect Result, @R
				MapWindowPoints 0, ParentHwnd, Cast(Point Ptr, @R), 2
				Return ControlAt(GetControl(Result), X - R.Left, Y - R.Top)
			End If
			'		dim as RECT R
			'		GetChilds(Parent)
			'		for i as integer = 0 to FChilds.Count -1
			'			if IsWindowVisible(FChilds.Child[i]) then
			'			   GetWindowRect(FChilds.Child[i], @R)
			'			   MapWindowPoints(0, Parent, cast(POINT ptr, @R) ,2)
			'			   if (X > R.Left and X < R.Right) and (Y > R.Top and Y < R.Bottom) then
			'				  return FChilds.Child[i]
			'			   end If
			'			end if
			'		next i
		#endif
		'    return Parent
	End Function
	
	#ifdef __USE_GTK__
		Function Dot_Draw(widget As GtkWidget Ptr, cr As cairo_t Ptr, data1 As Any Ptr) As Boolean
			Dim As Designer Ptr Des = data1
			If Des->SelectedControl AndAlso Des->SelectedControl = g_object_get_data(G_OBJECT(widget), "@@@Control2") Then
				cairo_set_source_rgb(cr, 255.0, 255.0, 255.0)
			Else
				cairo_set_source_rgb(cr, 0.0, 0.0, 0.0)
			End If
			cairo_rectangle(cr, 0, 0, 6, 6)
			cairo_fill_preserve(cr)
			If Des->SelectedControl AndAlso Des->SelectedControl = g_object_get_data(G_OBJECT(widget), "@@@Control2") Then
				cairo_set_source_rgb(cr, 0.0, 0.0, 0.0)
			Else
				cairo_set_source_rgb(cr, 255.0, 255.0, 255.0)
			End If
			cairo_stroke(cr)
			Return False
		End Function
		
		Function Dot_ExposeEvent(widget As GtkWidget Ptr, Event As GdkEventExpose Ptr, data1 As Any Ptr) As Boolean
			Dim As cairo_t Ptr cr = gdk_cairo_create(Event->window)
			Dot_Draw(widget, cr, data1)
			cairo_destroy(cr)
			Return False
		End Function
	#endif
	
	Sub Designer.CreateDots(ParentCtrl As Control Ptr)
		#ifdef __USE_GTK__
			Dim As GdkDisplay Ptr pdisplay
			Dim As GdkCursor Ptr gcurs
		#endif
		For i As Integer = 0 To 7
			#ifdef __USE_GTK__
				FDots(0, i) = gtk_layout_new(NULL, NULL)
				'g_object_ref(FDots(i))
				gtk_layout_put(gtk_layout(ParentCtrl->layoutwidget), FDots(0, i), 0, 0)
				gtk_widget_set_size_request(FDots(0, i), FDotSize, FDotSize)
				#ifdef __USE_GTK3__
					g_signal_connect(FDots(0, i), "draw", G_CALLBACK(@Dot_Draw), @This)
				#else
					g_signal_connect(FDots(0, i), "expose-event", G_CALLBACK(@Dot_ExposeEvent), @This)
				#endif
				gtk_widget_realize(FDots(0, i))
				pdisplay = gtk_widget_get_display(FDots(0, i))
				Select Case i
				Case 0, 4 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNWSE)
				Case 1, 5 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNS)
				Case 2, 6 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNESW)
				Case 3, 7 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeWE)
				End Select
				#ifdef __USE_GTK3__
					gdk_window_set_cursor(gtk_widget_get_window(FDots(0, i)), gcurs)
				#else
					gdk_window_set_cursor(gtk_layout_get_bin_window(gtk_layout(FDots(0, i))), gcurs)
				#endif
			#else
				FDots(0, i) = CreateWindowEx(0, "DOT", "", WS_CHILD Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN, 0, 0, FDotSize, FDotSize, ParentCtrl->Handle, 0, instance, 0)
				If IsWindow(FDots(0, i)) Then 
					SetWindowLongPtr(FDots(0, i), GWLP_USERDATA, CInt(@This))
				End If
			#endif
		Next i
	End Sub
	
	Sub Designer.DestroyDots
		For j As Integer = UBound(FDots) To 0 Step -1
			For i As Integer = 7 To 0 Step -1
				#ifdef __USE_GTK__
					gtk_widget_destroy(FDots(j, i))
				#else
					DestroyWindow(FDots(j, i))
				#endif
			Next i
		Next j
	End Sub
	
	Sub Designer.HideDots
		For j As Integer = 0 To UBound(FDots)
			For i As Integer = 0 To 7
				#ifdef __USE_GTK__
					If gtk_is_widget(FDots(j, i)) Then gtk_widget_set_visible(FDots(j, i), False)
				#else
					ShowWindow(FDots(j, i), SW_HIDE)
				#endif
			Next i
		Next j
	End Sub
	
	#ifdef __USE_GTK__
		Sub ScreenToClient(widget As GtkWidget Ptr, P As Point Ptr)
			Dim As gint x, y
			gdk_window_get_origin(gtk_widget_get_window(widget), @x, @y)
			P->x = P->x - x
			P->y = P->y - y
		End Sub
	#endif
	
	#ifdef __USE_GTK__
		Sub GetPosToClient(widget As GtkWidget Ptr, Client As GtkWidget Ptr, x As Integer Ptr, y As Integer Ptr, x1 As Integer = -1, y1 As Integer = -1)
			If widget = 0 Or widget = Client Then Return
			Dim allocation As GtkAllocation
			gtk_widget_get_allocation(widget, @allocation)
			*x = *x + allocation.x
			*y = *y + allocation.y
			If x1 <> -1 Then *x = x1
			If y1 <> -1 Then *y = y1
			GetPosToClient gtk_widget_get_parent(widget), Client, x, y
		End Sub
		
		Sub Designer.MoveDots(Control As Any Ptr, bSetFocus As Boolean = True, Left1 As Integer = -1, Top1 As Integer = -1, Width1 As Integer = -1, Height1 As Integer = -1)
	#else
		Sub Designer.MoveDots(Control As Any Ptr, bSetFocus As Boolean = True)
	#endif
		Dim As RECT R
		Dim As Point P
		Dim As Integer iWidth, iHeight
		#ifdef __USE_GTK__
			Dim As GtkWidget Ptr ControlHandle, ControlHandle2
		#else
			Dim As HWND ControlHandle
		#endif
		ControlHandle = GetControlHandle(Control)
		#ifdef __USE_GTK__
			If gtk_is_widget(ControlHandle) Then
		#else
			If IsWindow(ControlHandle) Then
		#endif
			SelectedControl = Control
			FSelControl = ControlHandle
			If SelectedControls.Count = 0 Then SelectedControls.Add SelectedControl
			'if Control <> FDialog then
			Dim As Integer DotsCount = UBound(FDots)
			For j As Integer = DotsCount To SelectedControls.Count Step -1
				For i As Integer = 7 To 0 Step -1
					#ifdef __USE_GTK__
						If gtk_is_widget(FDots(j, i)) Then gtk_container_remove(gtk_container(FDialogParent), FDots(j, i))
					#else
						DestroyWindow(FDots(j, i))
					#endif
				Next
			Next
			ReDim Preserve FDots(SelectedControls.Count - 1, 7) As CtrlHandle
			#ifdef __USE_GTK__
				Dim As Integer x, y ', x1, y1
				'			gtk_widget_set_has_window(Control, True)
				'			gtk_widget_set_has_window(FDialogParent, True)
				'  	      	gtk_widget_realize(Control)
				'  	      	gtk_widget_realize(FDialogParent)
				'  	      	gdk_window_get_origin(gtk_widget_get_window(Control), @x, @y)
				'  	      	gdk_window_get_origin(gtk_widget_get_window(FDialogParent), @x1, @y1)
				For j As Integer = 0 To SelectedControls.Count - 1
					ControlHandle2 = GetControlHandle(SelectedControls.Items[j])
					gtk_widget_realize(ControlHandle2)
					#ifdef __USE_GTK3__
						iWidth = gtk_widget_get_allocated_width(ControlHandle2)
						iHeight = gtk_widget_get_allocated_height(ControlHandle2)
					#else
						iWidth = ControlHandle2->allocation.width
						iHeight = ControlHandle2->allocation.height
					#endif
					x = 0
					y = 0
					If ControlHandle2 = ControlHandle Then
						If Width1 <> -1 Then iWidth = Width1
						If Height1 <> -1 Then iHeight = Height1
						GetPosToClient ControlHandle2, FDialogParent, @x, @y, Left1, Top1
					Else
						GetPosToClient ControlHandle2, FDialogParent, @x, @y
					End If
					P.x     = x
					P.y     = y
					Dim As GdkDisplay Ptr pdisplay
					Dim As GdkCursor Ptr gcurs
					For i As Integer = 0 To 7
						If gtk_is_widget(FDots(j, i)) Then gtk_container_remove(gtk_container(FDialogParent), FDots(j, i))
						FDots(j, i) = gtk_layout_new(NULL, NULL)
						gtk_widget_set_size_request(FDots(j, i), 6, 6)
						gtk_widget_set_events(FDots(j, i), _
						GDK_EXPOSURE_MASK Or _
						GDK_SCROLL_MASK Or _
						GDK_STRUCTURE_MASK Or _
						GDK_KEY_PRESS_MASK Or _
						GDK_KEY_RELEASE_MASK Or _
						GDK_FOCUS_CHANGE_MASK Or _
						GDK_LEAVE_NOTIFY_MASK Or _
						GDK_BUTTON_PRESS_MASK Or _
						GDK_BUTTON_RELEASE_MASK Or _
						GDK_POINTER_MOTION_MASK Or _
						GDK_POINTER_MOTION_HINT_MASK)
						g_signal_connect(FDots(j, i), "event", G_CALLBACK(@DotWndProc), @This)
						#ifdef __USE_GTK3__
							g_signal_connect(FDots(j, i), "draw", G_CALLBACK(@Dot_Draw), @This)
						#else
							g_signal_connect(FDots(j, i), "expose-event", G_CALLBACK(@Dot_ExposeEvent), @This)
						#endif
						Select Case i
						Case 0: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 0), P.X-6, P.Y-6)
						Case 1: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 1), P.X+iWidth/2-3, P.Y-6)
						Case 2: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 2), P.X+iWidth, P.Y-6)
						Case 3: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 3), P.X+iWidth, P.Y + iHeight/2-3)
						Case 4: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 4), P.X+iWidth, P.Y + iHeight)
						Case 5: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 5), P.X+iWidth/2-3, P.Y + iHeight)
						Case 6: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 6), P.X-6, P.Y + iHeight)
						Case 7: gtk_layout_put(gtk_layout(FDialogParent), FDots(j, 7), P.X-6, P.Y + iHeight/2-3)
						End Select
						gtk_widget_realize(FDots(j, i))
						pdisplay = gtk_widget_get_display(FDots(j, i))
						Select Case i
						Case 0, 4 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNWSE)
						Case 1, 5 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNS)
						Case 2, 6 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeNESW)
						Case 3, 7 : gcurs = gdk_cursor_new_from_name(pdisplay, crSizeWE)
						End Select
						#ifdef __USE_GTK3__
							gdk_window_set_cursor(gtk_widget_get_window(FDots(j, i)), gcurs)
						#else
							gdk_window_set_cursor(gtk_layout_get_bin_window(gtk_layout(FDots(j, i))), gcurs)
						#endif
						g_object_set_data(G_OBJECT(FDots(j, i)), "@@@Control", ControlHandle2)
						g_object_set_data(G_OBJECT(FDots(j, i)), "@@@Control2", SelectedControls.Items[j])
						'SetParent(FDots(i), GetParent(Control))
						'SetProp(FDots(i),"@@@Control", Control)
						'BringWindowToTop FDots(i)
						'gdk_window_raise(gtk_widget_get_window(FDots(i)))
						gtk_widget_show(FDots(j, i))
					Next i
				Next j
			#else
				For j As Integer = DotsCount + 1 To SelectedControls.Count - 1
					For i As Integer = 0 To 7
						FDots(j, i) = CreateWindowEx(0, "DOT", "", WS_CHILD Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN, 0, 0, FDotSize, FDotSize, GetParent(FDialog), 0, instance, 0)
						SetWindowLongPtr(FDots(j, i), GWLP_USERDATA, CInt(@This))
					Next
				Next
				For j As Integer = 0 To SelectedControls.Count - 1
					GetWindowRect(GetControlHandle(SelectedControls.Items[j]), @R)
					iWidth  = R.Right  - R.Left
					iHeight = R.Bottom - R.Top
					P.x     = R.Left
					P.y     = R.Top
					ScreenToClient(GetParent(FDialog), @P)
					MoveWindow FDots(j, 0), P.X-6, P.Y-6, 6, 6, True
					MoveWindow FDots(j, 1), P.X+iWidth/2-3, P.Y-6, 6, 6, True
					MoveWindow FDots(j, 2), P.X+iWidth, P.Y-6, 6, 6, True
					MoveWindow FDots(j, 3), P.X+iWidth, P.Y + iHeight/2-3, 6, 6, True
					MoveWindow FDots(j, 4), P.X+iWidth, P.Y + iHeight, 6, 6, True
					MoveWindow FDots(j, 5), P.X+iWidth/2-3, P.Y + iHeight, 6, 6, True
					MoveWindow FDots(j, 6), P.X-6, P.Y + iHeight, 6, 6, True
					MoveWindow FDots(j, 7), P.X-6, P.Y + iHeight/2-3, 6, 6, True
					For i As Integer = 0 To 7
						'SetParent(FDots(i), GetParent(Control))
						SetProp(FDots(j, i),"@@@Control", GetControlHandle(SelectedControls.Items[j]))
						SetProp(FDots(j, i),"@@@Control2", SelectedControls.Items[j])
						BringWindowToTop FDots(j, i)
						ShowWindow(FDots(j, i), SW_SHOW)
					Next i
				Next j
				FHDC = GetDC(GetParent(ControlHandle))
				'SetROP2(hdc, R2_NOTXORPEN)
				RedrawWindow(FDialog, NULL, NULL, RDW_INVALIDATE)
				'DrawFocusRect(Fhdc, @type<RECT>(R.Left, R.Top, R.Right, R.Bottom + 10))
				ReleaseDC(ControlHandle, Fhdc)
			#endif
			If bSetFocus Then
				#ifdef __USE_GTK__
					gtk_widget_grab_focus(layoutwidget)
				#else
					'SetFocus(Dialog)
				#endif
				'else
				'   HideDots
				'end If
				If OnChangeSelection Then OnChangeSelection(This, SelectedControl, p.x, p.y, iWidth, iHeight)
			End If
		Else
			HideDots
		End If
	End Sub
	
	#ifdef __USE_GTK__
		Function Designer.IsDot(hDlg As GtkWidget Ptr) As Integer
			Dim As String s
			'if UCase(s) = "DOT" then
			For j As Integer = 0 To SelectedControls.Count - 1
				For i As Integer = 0 To 7
					If FDots(j, i) = hDlg Then Return i
				Next i
			Next j
			Return -1
		End Function
	#else
		Function Designer.IsDot(hDlg As HWND) As Integer
			Dim As String s
			If GetWindowLongPtr(hDlg, GWLP_USERDATA) = CInt(@This) Then
				'if UCase(s) = "DOT" then
				For j As Integer = 0 To SelectedControls.Count - 1
					For i As Integer = 0 To 7
						If FDots(j, i) = hDlg Then Return i
					Next i
				Next j
			End If
			Return -1
		End Function
	#endif
	
	Sub Designer.DblClick(X As Integer, Y As Integer, Shift As Integer)
		'#IfDef __USE_GTK__
		SelectedControl = ControlAt(DesignControl, X, Y)
		If OnDblClickControl Then OnDblClickControl(This, SelectedControl)
		'#Else
		'    FSelControl = ControlAt(FDialog, X, Y)
		'	If OnDblClickControl Then OnDblClickControl(This, GetControl(FSelControl))
		'#EndIf
	End Sub
	
	#ifdef __USE_GTK__
		Function Designer.GetControlHandle(Control As Any Ptr) As GtkWidget Ptr
			Return ReadPropertyFunc(Control, "Widget")
	#else
		Function Designer.GetControlHandle(Control As Any Ptr) As HWND
			If Control = 0 Then Return 0
			Return *Cast(HWND Ptr, ReadPropertyFunc(Control, "Handle"))
	#endif
	End Function
	
	Sub Designer.MouseDown(X As Integer, Y As Integer, Shift As Integer)
		#ifdef __USE_GTK__
			Dim As Boolean bCtrl = Shift And GDK_Control_MASK
			Dim As Boolean bShift = Shift And GDK_Shift_MASK
		#else
			Dim As Boolean bCtrl = GetKeyState(VK_CONTROL) And 8000
			Dim As Boolean bShift = GetKeyState(VK_SHIFT) And 8000
		#endif
		Dim As Point P
		Dim As RECT R
		FDown   = True
		FStepX = GridSize
		FStepY = GridSize
		FBeginX = IIf(SnapToGridOption, (X\FStepX)*FStepX,X)
		FBeginy = IIf(SnapToGridOption, (Y\FStepY)*FStepY,y)
		FEndX   = FBeginX
		FEndY   = FBeginY
		FNewX   = FBeginX
		FNewY   = FBeginY
		HideDots
		Dim As Any Ptr SelCtrl = ControlAt(DesignControl, X, Y)
		FDotIndex   = IsDot(FOverControl)
		If FDotIndex = -1 Then
			If bCtrl Or bShift Then
				If SelectedControls.Contains(SelCtrl) Then
					If SelectedControls.Count > 1 Then SelectedControls.Remove SelectedControls.IndexOf(SelCtrl)
					SelectedControl = SelectedControls.Items[0]
				ElseIf SelectedControls.Count = 0 OrElse (ReadPropertyFunc <> 0 AndAlso ReadPropertyFunc(SelectedControls.Items[0], "Parent") = ReadPropertyFunc(SelCtrl, "Parent")) Then
					SelectedControls.Add SelCtrl
					SelectedControl = SelCtrl
				End If
			ElseIf Not SelectedControls.Contains(SelCtrl) Then
				SelectedControls.Clear
				SelectedControls.Add SelCtrl
				SelectedControl = SelCtrl
			Else
				SelectedControl = SelCtrl
			End If
		End If
		FSelControl = GetControlHandle(SelectedControl)
		If FDotIndex <> -1 Then
			FCanInsert  = False
			FCanMove    = False
			FCanSize    = True
			#ifdef __USE_GTK__
				If g_is_object(FDots(0, FDotIndex)) Then
					FSelControl = g_object_get_data(G_OBJECT(FDots(0, FDotIndex)), "@@@Control")
					SelectedControl = g_object_get_data(G_OBJECT(FDots(0, FDotIndex)), "@@@Control2")
				End If
			#else
				'If Not IsWindow(FSelControl) Then
				FSelControl = GetProp(FDots(0, FDotIndex),"@@@Control")
				SelectedControl = GetControl(FSelControl)
				'End If
			#endif   
			'BringWindowToTop(FSelControl)
			Dim As Integer iCount = SelectedControls.Count - 1
			ReDim As Integer FLeft(iCount), FTop(iCount), FWidth(iCount), FHeight(iCount)
			ReDim As Integer FLeftNew(iCount), FTopNew(iCount), FWidthNew(iCount), FHeightNew(iCount)
			For j As Integer = 0 To iCount
				#ifdef __USE_GTK__
					ControlGetBoundsSub(SelectedControls.Items[j], @FLeft(j), @FTop(j), @FWidth(j), @FHeight(j))
				#else
					GetWindowRect(GetControlHandle(SelectedControls.Items[j]), @R)
					P.X         = R.Left
					P.Y         = R.Top
					FWidth(j)   = R.Right - R.Left
					FHeight(j)  = R.Bottom - R.Top
					ScreenToClient(GetParent(FSelControl), @P) 
					FLeft(j)    = P.X
					FTop(j)     = P.Y
				#endif
			Next
			#ifndef __USE_GTK__
				Select Case FDotIndex
				Case 0: SetCursor(crSizeNWSE)
				Case 1: SetCursor(crSizeNS)
				Case 2: SetCursor(crSizeNESW)
				Case 3: SetCursor(crSizeWE)
				Case 4: SetCursor(crSizeNWSE)
				Case 5: SetCursor(crSizeNS)
				Case 6: SetCursor(crSizeNESW)
				Case 7: SetCursor(crSizeWE)
				End Select
				SetCapture(FDialog)
			#endif
		Else
			If FSelControl <> FDialog Then
				'BringWindowToTop(FSelControl)
				If ClassExists Then
					FCanInsert = True
					FCanMove   = False
					FCanSize   = False
					#ifdef __USE_GTK__
						gdk_window_set_cursor(gtk_widget_get_window(layoutwidget), gdk_cursor_new_from_name(gtk_widget_get_display(layoutwidget), crCross))
					#else
						SetCursor(crCross)
					#endif
				Else
					FCanInsert = False
					FCanMove   = True
					FCanSize   = False
					#ifdef __USE_GTK__
						gdk_window_set_cursor(gtk_widget_get_window(layoutwidget), gdk_cursor_new_from_name(gtk_widget_get_display(layoutwidget), crSize))
					#else
						SetCursor(crSize) :SetCapture(FDialog)
					#endif
					If OnChangeSelection Then OnChangeSelection(This, SelectedControl)
					Dim As Integer iCount = SelectedControls.Count - 1
					ReDim As Integer FLeft(iCount), FTop(iCount), FWidth(iCount), FHeight(iCount)
					ReDim As Integer FLeftNew(iCount), FTopNew(iCount), FWidthNew(iCount), FHeightNew(iCount)
					For j As Integer = 0 To iCount
						#ifdef __USE_GTK__
							ControlGetBoundsSub(SelectedControls.Items[j], @FLeft(j), @FTop(j), @FWidth(j), @FHeight(j))
						#else
							GetWindowRect(GetControlHandle(SelectedControls.Items[j]), @R)
							P.X         = R.Left
							P.Y         = R.Top
							FWidth(j)   = R.Right - R.Left
							FHeight(j)  = R.Bottom - R.Top
							ScreenToClient(GetParent(FSelControl), @P)
							FLeft(j)    = P.X
							FTop(j)     = P.Y
						#endif
					Next
				End If
			Else
				HideDots
				FCanInsert = IIf(ClassExists, True, False)
				FCanMove   = 0
				FCanSize   = False
				If FCanInsert Then
					#ifdef __USE_GTK__
						gdk_window_set_cursor(gtk_widget_get_window(layoutwidget), gdk_cursor_new_from_name(gtk_widget_get_display(layoutwidget), crCross))
					#else
						SetCursor(crCross)
					#endif
				Else
					If OnChangeSelection Then OnChangeSelection(This, SelectedControl)
				End If
				If Not FCanInsert And Not FCanMove Then
					#ifndef __USE_GTK__
						FHDC = GetDC(FDialog)
						'SetROP2(hdc, R2_NOTXORPEN)
						DrawFocusRect(Fhdc, @Type<RECT>(FBeginX, FBeginY, FNewX, FNewY))
						FOldX = FNewX
						FOldY = FNewY
						ReleaseDC(FDialog, Fhdc)
						SetCapture(FDialog)
					#endif
				End If
			End If
		End If   
	End Sub
	
	Sub Designer.MouseMove(X As Integer, Y As Integer, Shift As Integer)
		Dim As Point P
		FStepX = GridSize
		FStepY = GridSize
		FNewX = IIf(SnapToGridOption,(X\FStepX)*FStepX,X)
		FNewY = IIf(SnapToGridOption,(Y\FStepY)*FStepY,Y)
		'dim hdc As HDC = GetDC(FHandle)
		If FDown Then
			If FCanInsert Then
				#ifdef __USE_GTK__
					gtk_widget_queue_draw(layoutwidget)
				#else
					SetCursor(crCross)
				#endif
				DrawBox(Type<RECT>(FBeginX, FBeginY, FNewX, FNewY))
				DrawBox(Type<RECT>(FBeginX, FBeginY, FEndX, FEndY))    
			End If
			If FCanSize Then
				For j As Integer = 0 To SelectedControls.Count - 1
					FLeftNew(j) = FLeft(j)
					FTopNew(j) = FTop(j)
					FWidthNew(j) = FWidth(j)
					FHeightNew(j) = FHeight(j)
					#ifdef __USE_GTK__
						Select Case FDotIndex
						Case 0: FLeftNew(j) = FLeft(j) + (FNewX - FBeginX): FTopNew(j) = FTop(j) + (FNewY - FBeginY): FWidthNew(j) = FWidth(j) - (FNewX - FBeginX): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 1: FTopNew(j) = FTop(j) + (FNewY - FBeginY): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 2: FTopNew(j) = FTop(j) + (FNewY - FBeginY): FWIdthNew(j) = FWidth(j) + (FNewX - FBeginX): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 3: FWidthNew(j) = FWidth(j) + (FNewX - FBeginX)
						Case 4: FWidthNew(j) = FWidth(j) + (FNewX - FBeginX): FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 5: FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 6: FLeftNew(j) = FLeft(j) + (FNewX - FBeginX): FWidthNew(j) = FWidth(j) - (FNewX - FBeginX): FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 7: FLeftNew(j) = FLeft(j) - (FBeginX - FNewX): FWidthNew(j) = FWidth(j) + (FBeginX - FNewX)
						End Select
						ControlSetBoundsSub(SelectedControls.Items[j], FLeftNew(j), FTopNew(j), FWidthNew(j), FHeightNew(j))
					#else
						Select Case FDotIndex
						Case 0: FLeftNew(j) = FLeft(j) + (FNewX - FBeginX): FTopNew(j) = FTop(j) + (FNewY - FBeginY): FWidthNew(j) = FWidth(j) - (FNewX - FBeginX): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 1: FTopNew(j) = FTop(j) + (FNewY - FBeginY): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 2: FTopNew(j) = FTop(j) + (FNewY - FBeginY): FWIdthNew(j) = FWidth(j) + (FNewX - FBeginX): FHeightNew(j) = FHeight(j) - (FNewY - FBeginY)
						Case 3: FWidthNew(j) = FWidth(j) + (FNewX - FBeginX)
						Case 4: FWidthNew(j) = FWidth(j) + (FNewX - FBeginX): FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 5: FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 6: FLeftNew(j) = FLeft(j) + (FNewX - FBeginX): FWidthNew(j) = FWidth(j) - (FNewX - FBeginX): FHeightNew(j) = FHeight(j) + (FNewY - FBeginY)
						Case 7: FLeftNew(j) = FLeft(j) - (FBeginX - FNewX): FWidthNew(j) = FWidth(j) + (FBeginX - FNewX)
						End Select
						'ControlSetBoundsSub(SelectedControl, FLeftNew, FTopNew, FWidthNew, FHeightNew)
						MoveWindow(GetControlHandle(SelectedControls.Items[j]), FLeftNew(j), FTopNew(j), FWidthNew(j), FHeightNew(j), True)
					#endif
				Next
				#ifndef __USE_GTK__
					RedrawWindow(FDialog, NULL, NULL, RDW_INVALIDATE)
				#endif
			End If
			If FCanMove Then
				If FBeginX <> FEndX Or FBeginY <> FEndY Then
					For j As Integer = 0 To SelectedControls.Count - 1
						#ifdef __USE_GTK__
							ControlSetBoundsSub(SelectedControls.Items[j], FLeft(j) + (FNewX - FBeginX), FTop(j) + (FNewY - FBeginY), FWidth(j), FHeight(j))
						#else
							MoveWindow(GetControlHandle(SelectedControls.Items[j]), FLeft(j) + (FNewX - FBeginX), FTop(j) + (FNewY - FBeginY), FWidth(j), FHeight(j), True)
						#endif
					Next j
					#ifndef __USE_GTK__
						RedrawWindow(FDialog, NULL, NULL, RDW_INVALIDATE)
					#endif
				End If
			End If
			If Not FCanInsert And Not FCanMove And Not FCanSize Then
				#ifdef __USE_GTK__
					gtk_widget_queue_draw(layoutwidget)
				#else
					FHDC = GetDC(FDialog)
					'SetROP2(hdc, R2_NOTXORPEN)
					DrawFocusRect(Fhdc, @Type<RECT>(Min(FBeginX, FOldX), Min(FBeginY, FOldY), Max(FBeginX, FOldX), Max(FBeginY, FOldY)))
					DrawFocusRect(Fhdc, @Type<RECT>(Min(FBeginX, FNewX), Min(FBeginY, FNewY), Max(FBeginX, FNewX), Max(FBeginY, FNewY)))
				#endif
				FOldX = FNewX
				FOldY = FNewY
				#ifndef __USE_GTK__
					ReleaseDC(FDialog, Fhdc)
				#endif
			End If
		Else
			P = Type(X, Y)
			#ifdef __USE_GTK__
				
			#else
				ClientToScreen(FDialog, @P)
				ScreenToClient(GetParent(FDialog), @P)
				FOverControl = ChildWindowFromPoint(GetParent(FDialog), P)
				If OnMouseMove Then OnMouseMove(This, X, Y, GetControl(FOverControl))
				Dim As Integer Id = IsDot(FOverControl)
				If Id <> -1 Then
					Select Case Id
					Case 0 : SetCursor(crSizeNWSE)
					Case 1 : SetCursor(crSizeNS)
					Case 2 : SetCursor(crSizeNESW)
					Case 3 : SetCursor(crSizeWE)
					Case 4 : SetCursor(crSizeNWSE)
					Case 5 : SetCursor(crSizeNS)
					Case 6 : SetCursor(crSizeNESW)
					Case 7 : SetCursor(crSizeWE)
					End Select
				Else
					If GetAncestor(FOverControl,GA_ROOTOWNER) <> FDialog Then
						ReleaseCapture
					End If   
					SetCursor(crArrow)
					ClipCursor(0)
				End If
			#endif
		End If
		FEndX = FNewX
		FEndY = FNewY
	End Sub
	
	Function Designer.GetContainerControl(Ctrl As Any Ptr) As Any Ptr
		If ControlIsContainerFunc <> 0 Then
			If Ctrl Then
				If ControlIsContainerFunc(Ctrl) Then
					Return Ctrl
				ElseIf ReadPropertyFunc <> 0 AndAlso ReadPropertyFunc(Ctrl, "Parent") Then
					Return GetContainerControl(ReadPropertyFunc(Ctrl, "Parent"))
				End If
			End If
		End If
		Return Ctrl
	End Function
	
	Sub Designer.MouseUp(X As Integer, Y As Integer, Shift As Integer)
		Dim As RECT R
		If FDown Then
			'    	if (FBeginX > FEndX and FBeginY > FEndY) then
			'            swap FBeginX, FNewX
			'            swap FBeginY, FNewY
			'        end if
			'        if (FBeginX > FEndX and FBeginY < FEndY) then
			'            swap FBeginX, FNewX
			'        end if
			'        if (FBeginX < FEndX and FBeginY > FEndY) then
			'            swap FBeginY, FNewY
			'        end if
			FDown = False
			If Not FCanMove And Not FCanInsert And Not FCanSize Then
				If FBeginX > FNewX Then Swap FBeginX, FNewX
				If FBeginY > FNewY Then Swap FBeginY, FNewY
				SelectedControls.Clear
				#ifdef __USE_GTK__
					gtk_widget_queue_draw(layoutwidget)
					Dim As Integer ALeft, ATop, AWidth, AHeight
					Dim As Any Ptr Ctrl
					SelectedControl = DesignControl
					FSelControl = FDialog
					For i As Integer = 0 To iGet(ReadPropertyFunc(DesignControl, "ControlCount")) - 1
						Ctrl = ControlByIndexFunc(DesignControl, i)
						If Ctrl Then
							ControlGetBoundsSub(Ctrl, @ALeft, @ATop, @AWidth, @AHeight)
							If (ALeft > FBeginX And ALeft + AWidth < FNewX) And (ATop > FBeginY And ATop + AHeight < FNewY) Then
								If SelectedControls.Count = 0 OrElse (ReadPropertyFunc <> 0 AndAlso ReadPropertyFunc(SelectedControls.Items[0], "Parent") = ReadPropertyFunc(Ctrl, "Parent")) Then
									SelectedControls.Add Ctrl
								End If
							End If
						End If
					Next i
				#else
					FHDC = GetDC(FDialog)
					DrawFocusRect(Fhdc, @Type<RECT>(FBeginX, FBeginY, FNewX, FNewY))
					ReleaseDC(FDialog, Fhdc)
					SelectedControl = DesignControl
					FSelControl = FDialog
					Dim As RECT R
					GetChilds()
					For i As Integer = 0 To FChilds.Count -1
						If IsWindowVisible(FChilds.Child[i]) Then
							GetWindowRect(FChilds.Child[i], @R)
							MapWindowPoints(0, FDialog, Cast(Point Ptr, @R) ,2)
							If (R.Left > FBeginX And R.Right < FNewX) And (R.Top > FBeginY And R.Bottom < FNewY) Then
								If SelectedControls.Count = 0 OrElse (ReadPropertyFunc <> 0 AndAlso GetControl(FChilds.Child[i]) <> 0 AndAlso ReadPropertyFunc(SelectedControls.Items[0], "Parent") = ReadPropertyFunc(GetControl(FChilds.Child[i]), "Parent")) Then
									SelectedControls.Add GetControl(FChilds.Child[i])
								End If
							End If
						End If
					Next i
				#endif
				If SelectedControls.Count > 0 Then
					SelectedControl = SelectedControls.Items[0]
					FSelControl = GetControlHandle(SelectedControl)
				End If
				MoveDots(SelectedControl)
			End If
			If FCanInsert Then
				If FBeginX > FNewX Then Swap FBeginX, FNewX
				If FBeginY > FNewY Then Swap FBeginY, FNewY
				DrawBox(Type<RECT>(FBeginX, FBeginY, FNewX, FNewY))
				#ifdef __USE_GTK__
					gtk_widget_queue_draw(layoutwidget)
				#endif
				'if GetClassAcceptControls(GetClassName(FSelControl)) Then
				'R.Left   = FBeginX
				'R.Top    = FBeginY
				'R.Right  = FNewX
				'R.Bottom = FNewY
				'MapWindowPoints(FDialog, FSelControl, cast(POINT ptr, @R), 2)
				'if OnInsertingControl then
				'OnInsertingControl(this, FClass, FStyleEx, FStyle, FID)
				'end if   
				'CreateControl(FClass, "", "", FSelControl, R.Left, R.Top, R.Right -R.Left, R.Bottom -R.Top)
				'else
				FClass = SelectedClass
				If OnInsertingControl Then
					FName = SelectedClass
					OnInsertingControl(This, SelectedClass, FName)
				End If
				If SelectedType = 3 Or SelectedType = 4 Then
					Dim cpnt As Any Ptr = CreateComponent(SelectedClass, FName)
					If OnInsertComponent Then OnInsertComponent(This, FClass, cpnt)
				Else
					SelectedControl = GetContainerControl(SelectedControl)
					Dim As Rect R
					If SelectedControl <> DesignControl Then
						#ifndef __USE_GTK__
							GetWindowRect FSelControl, @R
							MapWindowPoints 0, FDialog, Cast(Point Ptr, @R), 2
						#endif
					End If
					Dim ctr As Any Ptr
					'#IfDef __USE_GTK__
					ctr = SelectedControl
					'#Else
					'	ctr = Cast(Any Ptr, GetWindowLongPtr(FSelControl, GWLP_USERDATA))
					'#EndIf
					CreateControl(SelectedClass, FName, FName, ctr, FBeginX - R.Left, FBeginY - R.Top, FNewX -FBeginX, FNewY -FBeginY)
					If FSelControl Then
						SelectedControls.Clear
						#ifdef __USE_GTK__
							Dim bTrue As Boolean = True
							WritePropertyFunc(SelectedControl, "Visible", @bTrue)
						#else
							LockWindowUpdate(FSelControl)
							BringWindowToTop(FSelControl)
						#endif
						If OnInsertControl Then OnInsertControl(This, FClass, SelectedControl, FBeginX - R.Left, FBeginY - R.Top, FNewX -FBeginX, FNewY -FBeginY)
						#ifdef __USE_GTK__
							MoveDots(SelectedControl, , FBeginX - R.Left, FBeginY - R.Top, FNewX -FBeginX, FNewY -FBeginY)
						#else
							MoveDots(SelectedControl)
							LockWindowUpdate(0)
						#endif
					Else
						SelectedControl = DesignControl
						MoveDots(SelectedControl)
					End If
				End If
				FCanInsert = False
			End If
			If FCanSize Then
				FCanSize = False
				If FBeginX <> FNewX OrElse FBeginY <> FNewY Then
					For j As Integer = 0 To SelectedControls.Count - 1
						If OnModified Then OnModified(This, SelectedControls.Items[j], FLeftNew(j), FTopNew(j), FWidthNew(j), FHeightNew(j))
					Next j
				End If
				MoveDots(SelectedControl)
			End If
			If FCanMove Then
				FCanMove = False
				If FBeginX <> FEndX OrElse FBeginY <> FEndY Then
					For j As Integer = 0 To SelectedControls.Count - 1
						If OnModified Then OnModified(This, SelectedControls.Items[j], FLeft(j) + (FEndX - FBeginX), FTop(j) + (FEndY - FBeginY), FWidth(j), FHeight(j))
					Next
				End If
				MoveDots(SelectedControl)
			End If
			FBeginX = FEndX
			FBeginY = FEndY
			FNewX   = FBeginX
			FNewY   = FBeginY
			#ifdef __USE_GTK__
				gdk_window_set_cursor(gtk_widget_get_window(layoutwidget), gdk_cursor_new_from_name(gtk_widget_get_display(layoutwidget), crArrow))
			#else
				ClipCursor(0)
				ReleaseCapture
			#endif
		Else
			#ifdef __USE_GTK__
				gdk_window_set_cursor(gtk_widget_get_window(layoutwidget), gdk_cursor_new_from_name(gtk_widget_get_display(layoutwidget), crArrow))
			#else
				ClipCursor(0)
			#endif
		End If
	End Sub
	
	Sub Designer.DeleteControls(Ctrl As Any Ptr, EventOnly As Boolean = False)
		For i As Integer = 0 To iGet(ReadPropertyFunc(Ctrl, "ControlCount")) - 1
			DeleteControls ControlByIndexFunc(Ctrl, i), EventOnly
		Next
		If OnDeleteControl Then OnDeleteControl(This, Ctrl)
		If EventOnly Then
			If ControlFreeWndSub Then ControlFreeWndSub(Ctrl)
		Else
			If RemoveControlSub Then RemoveControlSub(DesignControl, Ctrl)
			If DeleteComponentFunc Then DeleteComponentFunc(Ctrl)
		End If
		'if OnModified then OnModified(this, Ctrl, -1, -1, -1, -1)
	End Sub
	
	Sub Designer.DeleteControl()
		If SelectedControl Then
			If SelectedControl <> DesignControl Then
				For i As Integer = 0 To SelectedControls.Count - 1
					DeleteControls SelectedControls.Item(i)
				Next
				FSelControl = FDialog
				SelectedControls.Clear
				SelectedControl = DesignControl
				SelectedControls.Add SelectedControl
				MoveDots SelectedControl
			End If
		End If
	End Sub
	'sub Designer.DeleteControl(hDlg as HWND)
	'	if IsWindow(hDlg) then
	'		if hDlg <> FDialog then
	'		   if OnDeleteControl then OnDeleteControl(this, GetControl(hDlg))
	'		   DestroyWindow(hDlg)
	'		   if OnModified then OnModified(this, GetControl(hDlg))
	'		   FSelControl = FDialog
	'		   MoveDots SelectedControl
	'	   end if
	'	end if
	'end sub
	Dim Shared CopyList As List
	Sub Designer.CopyControl()
		CopyList.Clear
		#ifdef __USE_GTK__
			If gtk_is_widget(FSelControl) Then
		#else
			If IsWindow(FSelControl) Then
		#endif
			If FSelControl <> FDialog Then
				For j As Integer = 0 To SelectedControls.Count - 1
					CopyList.Add SelectedControls.Items[j]
				Next
				#ifndef __USE_GTK__
					'помещаем данные в буфер обмена
					Dim As UInteger fformat = RegisterClipboardFormat("VFEFormat") 'регистрируем наш формат данных
					If (OpenClipboard(NULL)) Then 'для работы с буфером обмена его нужно открыть
						'заполним нашу структуру данными
						Dim As HGLOBAL hgBuffer
						EmptyClipboard()  'очищаем буфер
						hgBuffer = GlobalAlloc(GMEM_DDESHARE, SizeOf(UInteger)) 'выделим память
						Dim As UInteger Ptr buffer = Cast(UInteger Ptr, GlobalLock(hgBuffer))
						'запишем данные в память
						*buffer = Cast(UInteger, @CopyList)
						'поместим данные в буфер обмена
						GlobalUnlock(hgBuffer)
						SetClipboardData(fformat, hgBuffer) 'помещаем данные в буфер обмена
						CloseClipboard() 'после работы с буфером, его нужно закрыть
					End If
				#endif
			End If
		End If
	End Sub
	
	Sub Designer.CutControl()
		#ifdef __USE_GTK__
			If gtk_is_widget(FSelControl) Then
		#else
			If IsWindow(FSelControl) Then
		#endif
			If FSelControl <> FDialog Then
				CopyControl
				For j As Integer = 0 To SelectedControls.Count - 1
					DeleteControls SelectedControls.Items[j], True
				Next
				'if OnModified then OnModified(this, GetControl(FSelControl))
				FSelControl = FDialog
				SelectedControl = DesignControl
				MoveDots SelectedControl
			End If
		End If
	End Sub
	
	Sub Designer.AddPasteControls(Ctrl As Any Ptr, ParentCtrl As Any Ptr, bStart As Boolean)
		Dim As Integer iStepX, iStepY
		If bStart Then
			iStepX = GridSize
			iStepY = GridSize
		End If
		If OnInsertingControl Then
			FName = WGet(ReadPropertyFunc(Ctrl, "Name"))
			OnInsertingControl(This, WGet(ReadPropertyFunc(Ctrl, "ClassName")), FName)
		End If
		Dim As Integer FLeft, FTop, FWidth, FHeight
		ControlGetBoundsSub(Ctrl, @FLeft, @FTop, @FWidth, @FHeight)
		CreateControl(WGet(ReadPropertyFunc(Ctrl, "ClassName")), FName, WGet(ReadPropertyFunc(Ctrl, "Text")), ParentCtrl, FLeft + iStepX, FTop + iStepY, FWidth, FHeight)
		If FSelControl Then
			#ifndef __USE_GTK__
				LockWindowUpdate(FSelControl)
				BringWindowToTop(FSelControl)
			#endif
			If OnInsertControl Then OnInsertControl(This, WGet(ReadPropertyFunc(Ctrl, "ClassName")), SelectedControl, FLeft + iStepX, FTop + iStepY, FWidth, FHeight)
			If bStart Then SelectedControls.Add SelectedControl
		End If
		For i As Integer = 0 To iGet(ReadPropertyFunc(Ctrl, "ControlCount")) - 1
			AddPasteControls ControlByIndexFunc(Ctrl, i), SelectedControl, False
		Next
	End Sub
	
	Sub Designer.PasteControl()
		#ifndef __USE_GTK__
			If IsWindow(FSelControl) Then
				'прочитаем наши данные из буфера обмена
				'вызываем второй раз, чтобы просто получить формат
				Dim As UInteger fformat = RegisterClipboardFormat("VFEFormat")
		#else
			If gtk_is_widget(FSelControl) Then
		#endif
			Dim ParentCtrl As Any Ptr = GetControl(FSelControl)
			If ControlIsContainerFunc <> 0 AndAlso ReadPropertyFunc <> 0 Then
				If Not ControlIsContainerFunc(ParentCtrl) Then ParentCtrl = ReadPropertyFunc(ParentCtrl, "Parent")
			End If
			#ifndef __USE_GTK__
				If pClipBoard->HasFormat(fformat) Then
					If ( OpenClipboard(NULL) ) Then
						
						'извлекаем данные из буфера
						
						Dim As HANDLE hData = GetClipboardData(fformat)
						
						Dim As UInteger Ptr buffer = Cast(UInteger Ptr, GlobalLock( hData ))
						
						GlobalUnlock( hData )
						
						CloseClipboard()
						Dim As List Ptr Value = Cast(Any Ptr, *buffer)
			#else
				Dim As List Ptr Value = @CopyList
			#endif
			If ReadPropertyFunc <> 0 AndAlso ControlGetBoundsSub <> 0 Then
				SelectedControls.Clear
				For j As Integer = 0 To Value->Count - 1
					AddPasteControls Value->Items[j], ParentCtrl, True
				Next
				MoveDots(SelectedControl)
				#ifndef __USE_GTK__
					LockWindowUpdate(0)
				#endif
			End If
			#ifndef __USE_GTK__
			End If
		End If
			#endif
	'if OnModified then OnModified(this, GetControl(hDlg))
	'FSelControl = FDialog
End If
End Sub

#ifndef __USE_GTK__
	Sub Designer.UnHookControl(Control As HWND)
		If IsWindow(Control) Then
			If GetWindowLongPtr(Control, GWLP_WNDPROC) = @HookChildProc Then
				SetWindowLongPtr(Control, GWLP_WNDPROC, CInt(GetProp(Control, "@@@Proc")))
				RemoveProp(Control, "@@@Proc")
			End If
		End If   
	End Sub
#endif

#ifdef __USE_GTK__
	Sub Designer.HookControl(Control As GtkWidget Ptr)
#else
	Sub Designer.HookControl(Control As HWND)
#endif
	#ifdef __USE_GTK__
		If gtk_is_widget(Control) Then
			g_signal_connect(Control, "event", G_CALLBACK(@HookChildProc), @This)
		End If
	#else
		If IsWindow(Control) Then
			If GetWindowLongPtr(Control, GWLP_WNDPROC) <> @HookChildProc Then
				SetProp(Control, "@@@Proc", Cast(WNDPROC, SetWindowLongPtr(Control, GWLP_WNDPROC, CInt(@HookChildProc))))
			End If
		End If   
	#endif
End Sub

Function Designer.CreateControl(AClassName As String, AName As String, ByRef AText As WString, AParent As Any Ptr, x As Integer, y As Integer, cx As Integer, cy As Integer, bNotHook As Boolean = False) As Any Ptr
	On Error Goto ErrorHandler
	If FLibs.Contains(*MFFDll) Then
		MFF = FLibs.Object(FLibs.IndexOf(*MFFDll))
	Else
		MFF = DyLibLoad(*MFFDll)        
		FLibs.Add *MFFDll, MFF
	End If
	Ctrl = 0
	FSelControl = 0
	If MFF Then
		If CreateControlFunc <> 0 Then
			Ctrl = CreateControlFunc(AClassName, _
			AName, _
			AText, _
			x, _
			y, _
			IIf(cx, cx, 50),_
			IIf(cy, cy, 50),_
			AParent)
			If Ctrl Then
				SelectedControl = Ctrl
				If ReadPropertyFunc Then
					#ifdef __USE_GTK__
						'g_signal_connect(layoutwidget, "event", G_CALLBACK(@HookChildProc), Ctrl)
						Dim As GtkWidget Ptr hHandle = ReadPropertyFunc(Ctrl, "Widget")
						If hHandle <> 0 Then FSelControl = hHandle
					#else
						Dim As HWND Ptr hHandle = ReadPropertyFunc(Ctrl, "Handle")
						If hHandle <> 0 Then FSelControl = *hHandle
					#endif
				End If
				If WritePropertyFunc Then
					Dim As Boolean bTrue = True
					WritePropertyFunc(Ctrl, "DesignMode", @bTrue)
					WritePropertyFunc(Ctrl, "ControlDesigner", @This)
					#ifdef __USE_GTK__
						
					#else
						
					#endif
				End If
			Else
				
			End If
		End If
	End If
	SelectedClass = ""
	/'FSelControl = CreateWindowEx(FStyleEx,_
	AClassName,_
	AText,_
	FStyle or WS_VISIBLE or WS_CHILD or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,_
	x,_
	y,_
	iif(cx, cx, 50),_
	iif(cy, cy, 50),_
	AParent,_
	cast(HMENU, FID),_
	instance,_
	0)
	'/
	#ifdef __USE_GTK__
		If gtk_is_widget(FSelControl) Then
			If Not bNotHook Then
				HookControl(FSelControl)
				'AName = iif(AName="", AName = AClassName & ...)
				'SetProp(Control, "Name", ...)
				'possibly using in propertylist inspector
			End If
		End If
	#else
		If IsWindow(FSelControl) Then
			If Not bNotHook Then
				HookControl(FSelControl)
				'AName = iif(AName="", AName = AClassName & ...)
				'SetProp(Control, "Name", ...)
				'possibly using in propertylist inspector
			End If
		End If
	#endif
	'DyLibFree(MFF)
	Return Ctrl
	Exit Function
	ErrorHandler:
	MsgBox ErrDescription(Err) & " (" & Err & ") " & _
	"in line " & Erl() & " " & _
	"in function " & ZGet(Erfn()) & " " & _
	"in module " & ZGet(Ermn())
End Function

Function Designer.CreateComponent(AClassName As String, AName As String) As Any Ptr
	Dim CreateComponentFunc As Function(ClassName As String, ByRef Name As WString) As Any Ptr
	Dim MFF As Any Ptr
	If FLibs.Contains(*MFFDll) Then
		MFF = FLibs.Object(FLibs.IndexOf(*MFFDll))
	Else
		MFF = DyLibLoad(*MFFDll)        
		FLibs.Add *MFFDll, MFF
	End If
	Dim As Any Ptr Cpnt
	#ifndef __USE_GTK__
		FSelControl = 0
	#endif
	If MFF Then
		CreateComponentFunc = DyLibSymbol(MFF, "CreateComponent")
		If CreateComponentFunc <> 0 Then
			Cpnt = CreateComponentFunc(AClassName, AName)
			If Cpnt Then
				If WritePropertyFunc Then
					Dim As Boolean bTrue = True
					WritePropertyFunc(Cpnt, "DesignMode", @bTrue)
				End If
			End If
		End If
	End If
	SelectedClass = ""
	Return Cpnt
End Function

Sub Designer.UpdateGrid
	#ifndef __USE_GTK__
		InvalidateRect(FDialog, 0, True)
	#endif
End Sub

Sub Designer.DrawThis()
	FStepX = GridSize
	FStepY = GridSize
	#ifdef __USE_GTK__
		If ShowAlignmentGrid Then
			#ifdef __USE_GTK3__
				Dim As Integer iWidth = gtk_widget_get_allocated_width(layoutwidget)
				Dim As Integer iHeight = gtk_widget_get_allocated_height(layoutwidget)
			#else
				Dim As Integer iWidth = layoutwidget->allocation.width
				Dim As Integer iHeight = layoutwidget->allocation.height
			#endif
			cairo_set_source_rgb(cr, 0, 0, 0)
			For i As Integer = 1 To iWidth Step FStepX
				For j As Integer = 1 To iHeight Step FStepY
					cairo_rectangle(cr, i, j, 1, 1)
					cairo_fill(cr)
				Next j
			Next i
		End If
	#else
		Dim As HDC mDc
		Dim As HBITMAP mBMP, pBMP
		Dim As RECT R, BrushRect = Type(0, 0, FStepX, FStepY)
		Dim As PAINTSTRUCT Ps
		FHDc = BeginPaint(FDialog,@Ps)
		GetClientRect(FDialog, @R)
		If ShowAlignmentGrid Then
			If FGridBrush Then
				DeleteObject(FGridBrush)
			End If   
			mDc   = CreateCompatibleDc(FHDC)
			mBMP  = CreateCompatibleBitmap(FHDC, FStepX, FStepY)
			pBMP  = SelectObject(mDc, mBMP)
			FillRect(mDc, @BrushRect, Cast(HBRUSH, 16))
			SetPixel(mDc, 0, 0, 0)
			'for lines use MoveTo and LineTo or Rectangle function or whatever...
			FGridBrush = CreatePatternBrush(mBMP)
			FillRect(FHDC, @R, FGridBrush)
		Else
			FillRect(Fhdc, @R, Cast(HBRUSH, 16))
		End If
		For j As Integer = 0 To SelectedControls.Count - 1
			GetWindowRect(GetControlHandle(SelectedControls.Items[j]), @R)
			MapWindowPoints 0, FDialog, Cast(Point Ptr, @R), 2
			DrawFocusRect(Fhdc, @Type<RECT>(R.Left - 2, R.Top - 2, R.Right + 2, R.Bottom + 2))
		Next j
		If ShowAlignmentGrid Then
			SelectObject(mDc, pBMP)
			DeleteObject(mBMP)
			DeleteDc(mDc)
		End If
		EndPaint FDialog,@Ps
	#endif
End Sub

#ifdef __USE_GTK__
	Function Designer.HookChildProc(widget As GtkWidget Ptr, Event As GdkEvent Ptr, user_data As Any Ptr) As Boolean
#else
	Function Designer.HookChildProc(hDlg As HWND, uMsg As UINT, wParam As WPARAM, lParam As LPARAM) As LRESULT
#endif
	Static As My.Sys.Forms.Designer Ptr Des
	#ifdef __USE_GTK__
		Des = user_data
	#else
		Des = GetProp(hDlg, "@@@Designer")
	#endif
	If Des Then
		Dim As Point P
		With *Des
			#ifdef __USE_GTK__
				Select Case Event->Type
			#else
				Select Case uMsg
				Case WM_NCHitTest
				Case WM_GETDLGCODE: 'Return DLGC_WANTCHARS Or DLGC_WANTALLKEYS Or DLGC_WANTARROWS Or DLGC_WANTTAB
			#endif
				#ifdef __USE_GTK__
				Case GDK_EXPOSE
					Return False
				#else
				Case WM_PAINT
				#endif
				#ifdef __USE_GTK__
				Case GDK_2BUTTON_PRESS ', GDK_DOUBLE_BUTTON_PRESS
					Dim As Integer x, y
					GetPosToClient widget, .layoutwidget, @x, @y
					.DblClick(Event->Motion.x + x, Event->Motion.y + y, Event->Motion.state)
					Return True
				#else
				Case WM_LBUTTONDBLCLK
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.DblClick(P.X, P.Y, wParam And &HFFFF )
					'Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_PRESS
				#else
				Case WM_LBUTTONDOWN
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient widget, .layoutwidget, @x, @y
					.MouseDown(Event->button.x + x, Event->button.y + y, Event->button.state)
					If gtk_is_notebook(widget) AndAlso Event->button.y < 20 Then
						Return False
					Else
						Return True
					End If
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseDown(P.X, P.Y, wParam And &HFFFF )
					'Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_RELEASE
				#else
				Case WM_LBUTTONUP
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient widget, .layoutwidget, @x, @y
					.MouseUp(Event->button.x + x, Event->button.y + y, Event->button.state)
					If Event->button.button = 3 Then
						mnuDesigner.Popup(Event->button.x, Event->button.y, @Type<Message>(Des, widget, Event, False))
					End If
					If gtk_is_notebook(widget) AndAlso Event->button.y < 20 Then
						Return False
					Else
						Return True
					End If
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseUp(P.X, P.Y, wParam And &HFFFF )
					'Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_MOTION_NOTIFY
				#else
				Case WM_MOUSEMOVE
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient widget, .layoutwidget, @x, @y
					.FOverControl = Widget
					.MouseMove(Event->button.x + x, Event->button.y + y, Event->button.state)
					Return True
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseMove(P.X, P.Y, wParam And &HFFFF )
					'Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_KEY_PRESS
				#else
				Case WM_KEYDOWN
				#endif
				#ifdef __USE_GTK__
					.KeyDown(Event->Key.keyval, Event->Key.state)
				#else
					.KeyDown(wParam, 0)
				#endif
			End Select
		End With
	End If
	#ifdef __USE_GTK__
		Return True
	#else
		Return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
	#endif
	'#Else
	'Dim As Any Ptr Ctrl = Cast(Any Ptr, GetWindowLongPtr(hDlg, GWLP_USERDATA))
	'If Ctrl <> 0 AndAlso Des <> 0 AndAlso Des->ReadPropertyFunc <> 0 AndAlso QWString(Des->ReadPropertyFunc(Ctrl, "ClassAncestor")) = "" Then
	'Select Case uMsg
	
	'case WM_MOUSEFIRST to WM_MOUSELAST
	'	return true
	'case WM_NCHITTEST
	'	return HTTRANSPARENT
	'case WM_KEYFIRST to WM_KEYLAST
	'	return 0
	'end select
	'End If
	'return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
	'#EndIf
End Function

Sub Designer.SendToBack
	#ifndef __USE_GTK__
		SetWindowPos FSelControl, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE Or SWP_NOSIZE
	#endif
End Sub

#ifdef __USE_GTK__
	Function Designer.HookDialogProc(widget As GtkWidget Ptr, Event As GdkEvent Ptr, user_data As Any Ptr) As Boolean
#else
	Function Designer.HookDialogProc(hDlg As HWND, uMsg As UINT, wParam As WPARAM, lParam As LPARAM) As LRESULT
#endif
	Static As Boolean bCtrl, bShift
	Static As Any Ptr Ctrl
	Static As My.Sys.Forms.Designer Ptr Des
	#ifdef __USE_GTK__
		bShift = Event->Key.state And GDK_Shift_MASK
		bCtrl = Event->Key.state And GDK_Control_MASK
		Des = user_data
		'If ReadPropertyFunc Then Des = ReadPropertyFunc(Ctrl, "ControlDesigner")
	#else
		bShift = GetKeyState(VK_SHIFT) And 8000
		bCtrl = GetKeyState(VK_CONTROL) And 8000
		Des = GetProp(hDlg, "@@@Designer")
	#endif
	If Des Then
		With *Des
			#ifdef __USE_GTK__
				Select Case Event->Type
			#else
				Select Case uMsg
			#endif
				#ifndef __USE_GTK__
				Case WM_PAINT, WM_ERASEBKGND
					'Function = CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
					.DrawThis
					Return 1
					'Exit Function
				Case WM_NCHitTest
				Case WM_SYSCOMMAND
					Return 0
				Case WM_SETCURSOR
					Return 0
				Case WM_GETDLGCODE: Return DLGC_WANTCHARS Or DLGC_WANTALLKEYS Or DLGC_WANTARROWS Or DLGC_WANTTAB
				#endif
				#ifdef __USE_GTK__
				Case GDK_2BUTTON_PRESS ', GDK_DOUBLE_BUTTON_PRESS
					.DblClick(Event->Motion.x, Event->Motion.y, Event->Motion.state)
					Return True
				#else
				Case WM_LBUTTONDBLCLK
					.DblClick(LoWord(lParam), HiWord(lParam),wParam And &HFFFF)
					'Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_PRESS
					.MouseDown(Event->button.x, Event->button.y, Event->button.state)
					Return True
				#else
				Case WM_LBUTTONDOWN
					.MouseDown(LoWord(lParam), HiWord(lParam),wParam And &HFFFF )
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_RELEASE
					.MouseUp(Event->button.x, Event->button.y, Event->button.state)
					If Event->button.button = 3 Then
						mnuDesigner.Popup(Event->button.x, Event->button.y, @Type<Message>(Des, widget, Event, False))
					End If
					Return True
				#else
				Case WM_LBUTTONUP
					.MouseUp(LoWord(lParam), HiWord(lParam),wParam And &HFFFF )
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_MOTION_NOTIFY
					.FOverControl = Widget
					.MouseMove(Event->button.x, Event->button.y, Event->button.state)
					Return True
				#else
				Case WM_MOUSEMOVE
					.MouseMove(LoWord(lParam), HiWord(lParam),wParam And &HFFFF )
					'Return 0
				#endif
				#ifndef __USE_GTK__
				Case WM_RBUTTONUP
					'if .FSelControl <> .FDialog then
					Dim As Point P
					P.x = LoWord(lParam)
					P.y = HiWord(lParam)
					ClientToScreen(hDlg, @P)
					TrackPopupMenu(.FPopupMenu, 0, P.x, P.y, 0, hDlg, 0)
					'end if
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_KEY_PRESS
					.KeyDown(Event->Key.keyval, Event->Key.state)
					Return True
					'Select Case event->Key.keyval
				#else
				Case WM_KEYDOWN
					.KeyDown(wParam, 0)
					'Select Case wParam
				#endif
				'					Case Keys.DeleteKey
				'						If Des->FSelControl <> Des->FDialog Then Des->DeleteControl(Des->SelectedControl)
				'					Case Keys.Left, Keys.Right, Keys.Up, Keys.Down
				'						Dim As Integer FLeft, FTop, FWidth, FHeight
				'						Dim As Integer FStepX = Des->FStepX
				'						Dim As Integer FStepY = Des->FStepY
				'						If bCtrl Then FStepX = 1: FStepY = 1
				'						#IfDef __USE_GTK__
				'						#Else
				'							Dim As POINT P
				'							Dim As RECT R
				'							GetWindowRect(Des->FSelControl, @R)
				'							P.X     = R.Left
				'							P.Y     = R.Top
				'							FWidth  = R.Right - R.Left
				'							FHeight = R.Bottom - R.Top
				'							ScreenToClient(GetParent(Des->FSelControl), @P) 
				'							FLeft   = P.X
				'							FTop    = P.Y
				'							If bShift Then
				'								Select Case wParam
				'								Case Keys.Left: MoveWindow(Des->FSelControl, FLeft, FTop, FWidth - FStepX, FHeight, True)
				'								Case Keys.Right: MoveWindow(Des->FSelControl, FLeft, FTop, FWidth + FStepX, FHeight, True)
				'								Case Keys.Up: MoveWindow(Des->FSelControl, FLeft, FTop, FWidth, FHeight - FStepY, True)
				'								Case Keys.Down: MoveWindow(Des->FSelControl, FLeft, FTop, FWidth, FHeight + FStepY, True)
				'								End Select
				'							ElseIf Des->FSelControl <> Des->Dialog Then
				'								Select Case wParam
				'								Case Keys.Left: MoveWindow(Des->FSelControl, FLeft - FStepX, FTop, FWidth, FHeight, True)
				'								Case Keys.Right: MoveWindow(Des->FSelControl, FLeft + FStepX, FTop, FWidth, FHeight, True)
				'								Case Keys.Up: MoveWindow(Des->FSelControl, FLeft, FTop - FStepY, FWidth, FHeight, True)
				'								Case Keys.Down: MoveWindow(Des->FSelControl, FLeft, FTop + FStepY, FWidth, FHeight, True)
				'								End Select
				'							End If
				'							Des->MoveDots(Des->FSelControl)
				'							If Des->OnModified Then Des->OnModified(*Des, GetControl(Des->FSelControl))
				'						#EndIf
				'					End Select
				#ifndef __USE_GTK__
				Case WM_COMMAND
					If IsWindow(Cast(HWND, lParam)) Then
					Else
						If HiWord(wParam) = 0 Then
							Select Case LoWord(wParam)
							Case 10: .DeleteControl()
							Case 11: 'MessageBox(.FDialog, "Not implemented yet.","Designer", 0)
							Case 12: .CopyControl()
							Case 13: .CutControl()
							Case 14: .PasteControl()
							Case 16: .SendToBack()
							Case 18: If Des->OnClickProperties Then Des->OnClickProperties(*Des, .GetControl(.FSelControl))
							End Select
						End If
					End If '
					''''Call and execute the based commands of dialogue.
					'return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
					'''if don't want to call
					'return 0
				#endif
			End Select
		End With
	End If
	#ifdef __USE_GTK__
		Return False
	#else
		Return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
	#endif
End Function

#ifdef __USE_GTK__
	Function Designer.HookDialogParentProc(widget As GtkWidget Ptr, Event As GdkEvent Ptr, user_data As Any Ptr) As Boolean
#else
	Function Designer.HookDialogParentProc(hDlg As HWND, uMsg As UINT, wParam As WPARAM, lParam As LPARAM) As LRESULT
#endif
	Static As Designer Ptr Des
	#ifdef __USE_GTK__
		Des = user_data
	#else
		Des = GetProp(hDlg, "@@@Designer")
	#endif
	If Des Then
		With *Des
			Dim As Point P
			#ifdef __USE_GTK__
				Select Case Event->Type
			#else
				Select Case uMsg
				Case WM_NCHitTest
				Case WM_GETDLGCODE: Return DLGC_WANTCHARS Or DLGC_WANTALLKEYS Or DLGC_WANTARROWS Or DLGC_WANTTAB
			#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_PRESS
				#else
				Case WM_LBUTTONDOWN
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient(.layoutwidget, widget, @x, @y)
					.MouseDown(Event->button.x - x, Event->button.y - y, Event->button.state)
					Return True
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseDown(P.X, P.Y, wParam And &HFFFF )
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_RELEASE
				#else
				Case WM_LBUTTONUP
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient(.layoutwidget, widget, @x, @y)
					.MouseUp(Event->button.x - x, Event->button.y - y, Event->button.state)
					Return True
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseUp(P.X, P.Y, wParam And &HFFFF )
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_MOTION_NOTIFY
					'.FOverControl = Widget
				#else
				Case WM_MOUSEMOVE
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y
					GetPosToClient(.layoutwidget, widget, @x, @y)
					.MouseMove(Event->Motion.x - x, Event->Motion.y - y, Event->Motion.state)
					Return True
				#else
					P = Type<Point>(LoWord(lParam), HiWord(lParam))
					ClientToScreen(hDlg, @P)
					ScreenToClient(.FDialog, @P)
					.MouseMove(P.X, P.Y, wParam And &HFFFF )
					Return 0
				#endif
				#ifndef __USE_GTK__
				Case WM_COMMAND
					
					''''Call and execute the based commands of dialogue.
					Return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
					'''if don't want to call
					'return 0
				#endif
			End Select
		End With
	End If
	#ifdef __USE_GTK__
		Return False
	#else
		Return CallWindowProc(GetProp(hDlg, "@@@Proc"), hDlg, uMsg, wParam, lParam)
	#endif
End Function

Sub Designer.Hook
	#ifdef __USE_GTK__
		If gtk_is_widget(FDialog) Then
	#else
		If IsWindow(FDialog) Then
	#endif
		#ifdef __USE_GTK__
			g_signal_connect(layoutwidget, "event", G_CALLBACK(@HookDialogProc), @This)
		#else
			SetProp(FDialog, "@@@Designer", @This)
			If GetWindowLongPtr(FDialog, GWLP_WNDPROC) <> @HookDialogProc Then
				SetProp(FDialog, "@@@Proc", Cast(Any Ptr, SetWindowLongPtr(FDialog, GWLP_WNDPROC, CInt(@HookDialogProc))))
			End If
		#endif
		HookParent
		'GetChilds
		'for i as integer = 0 to FChilds.Count-1
		'	HookControl(FChilds.Child[i])
		'next
	End If
End Sub

Sub Designer.UnHook
	#ifndef __USE_GTK__
		SetWindowLongPtr(FDialog, GWLP_WNDPROC, CInt(GetProp(FDialog, "@@@Proc")))
		RemoveProp(FDialog, "@@@Designer")
		RemoveProp(FDialog, "@@@Proc")
		UnHookParent
		GetChilds
		For i As Integer = 0 To FChilds.Count-1
			UnHookControl(FChilds.Child[i])
		Next
	#endif
End Sub

Sub Designer.HookParent
	#ifdef __USE_GTK__
		If gtk_is_widget(FDialogParent) Then
			g_signal_connect(FDialogParent, "event", G_CALLBACK(@HookDialogParentProc), @This)
		End If
	#else
		If IsWindow(FDialog) Then
			SetProp(GetParent(FDialog), "@@@Designer", This)
			If GetWindowLongPtr(GetParent(FDialog), GWLP_WNDPROC) <> @HookDialogParentProc Then
				SetProp(GetParent(FDialog), "@@@Proc", Cast(Any Ptr, SetWindowLongPtr(GetParent(FDialog), GWLP_WNDPROC, CInt(@HookDialogParentProc))))
			End If
		End If
	#endif
End Sub

Sub Designer.UnHookParent
	#ifndef __USE_GTK__
		SetWindowLongPtr(GetParent(FDialog), GWLP_WNDPROC, CInt(GetProp(GetParent(FDialog), "@@@Proc")))
		RemoveProp(FDialog, "@@@Designer")
		RemoveProp(FDialog, "@@@Proc")
	#endif
End Sub

Sub Designer.KeyDown(KeyCode As Integer, Shift As Integer)
	Static bShift As Boolean
	Static bCtrl As Boolean
	#ifdef __USE_GTK__
		bShift = Shift And GDK_Shift_MASK
		bCtrl = Shift And GDK_Control_MASK
	#else
		bShift = GetKeyState(VK_SHIFT) And 8000
		bCtrl = GetKeyState(VK_CONTROL) And 8000
	#endif
	Select Case KeyCode
	Case Keys.DeleteKey: DeleteControl()
	Case Keys.Left, Keys.Right, Keys.Up, Keys.Down
		FStepX = GridSize
		FStepY = GridSize
		Dim As Integer FStepX1 = FStepX
		Dim As Integer FStepY1 = FStepY
		Dim As Integer FLeft, FTop, FWidth, FHeight
		If bCtrl Then FStepX1 = 1: FStepY1 = 1
		#ifdef __USE_GTK__
			If SelectedControl <> 0 Then
				For j As Integer = 0 To SelectedControls.Count - 1
					ControlGetBoundsSub(SelectedControls.Items[j], @FLeft, @FTop, @FWidth, @FHeight)
					If bShift Then
						Select Case KeyCode
						Case Keys.Left: FWidth = FWidth - FStepX1
						Case Keys.Right: FWidth = FWidth + FStepX1
						Case Keys.Up: FHeight = FHeight - FStepY1
						Case Keys.Down: FHeight = FHeight + FStepY1
						End Select
					ElseIf SelectedControl <> DesignControl Then
						Select Case KeyCode
						Case Keys.Left: FLeft = FLeft - FStepX1
						Case Keys.Right: FLeft = FLeft + FStepX1
						Case Keys.Up: FTop = FTop - FStepY1
						Case Keys.Down: FTop = FTop + FStepY1
						End Select
					End If
					ControlSetBoundsSub(SelectedControl, FLeft, FTop, FWidth, FHeight)
					MoveDots(SelectedControl, , FLeft, FTop, FWidth, FHeight)
					If OnModified Then OnModified(This, SelectedControls.Items[j], FLeft, FTop, FWidth, FHeight)
				Next
			EndIf
		#else
			Dim As Point P
			Dim As RECT R
			Dim As HWND ControlHandle
			For j As Integer = 0 To SelectedControls.Count - 1
				ControlHandle = GetControlHandle(SelectedControls.Items[j])
				GetWindowRect(ControlHandle, @R)
				P.X     = R.Left
				P.Y     = R.Top
				FWidth  = R.Right - R.Left
				FHeight = R.Bottom - R.Top
				ScreenToClient(GetParent(ControlHandle), @P) 
				FLeft   = P.X
				FTop    = P.Y
				If bShift Then
					Select Case KeyCode
					Case Keys.Left: FWidth = FWidth - FStepX1
					Case Keys.Right: FWidth = FWidth + FStepX1
					Case Keys.Up: FHeight = FHeight - FStepY1
					Case Keys.Down: FHeight = FHeight + FStepY1
					End Select
				ElseIf ControlHandle <> Dialog Then
					Select Case KeyCode
					Case Keys.Left: FLeft = FLeft - FStepX1
					Case Keys.Right: FLeft = FLeft + FStepX1
					Case Keys.Up: FTop = FTop - FStepY1
					Case Keys.Down: FTop = FTop + FStepY1
					End Select
				End If
				MoveWindow(ControlHandle, FLeft, FTop, FWidth, FHeight, True)
				If OnModified Then OnModified(This, SelectedControls.Items[j], FLeft, FTop, FWidth, FHeight)
			Next
			MoveDots(SelectedControl)
		#endif
	End Select
End Sub

#ifdef __USE_GTK__
	Function Designer.DotWndProc(widget As GtkWidget Ptr, Event As GdkEvent Ptr, user_data As Any Ptr) As Boolean
#else
	Function Designer.DotWndProc(hDlg As HWND, uMsg As UINT, wParam As WPARAM, lParam As LPARAM) As LRESULT
#endif
	Dim As Designer Ptr Des 
	#ifdef __USE_GTK__
		Des = user_data
	#else
		Des = Cast(Designer Ptr, GetWindowLongPtr(hDlg, GWLP_USERDATA))
	#endif
	If Des Then
		With *Des
			#ifdef __USE_GTK__
				Select Case Event->Type
			#else
				Select Case uMsg
				Case WM_PAINT
					Dim As PAINTSTRUCT Ps
					Dim As HDC FHDc = BeginPaint(hDlg, @Ps)
					FillRect(FHDc, @Ps.rcPaint, IIf(GetProp(hDlg, "@@@Control2") = .SelectedControl, Cast(HBRUSH, GetStockObject(BLACK_BRUSH)), Cast(HBRUSH, GetStockObject(WHITE_BRUSH))))
					Dim As HBrush Brush = IIf(GetProp(hDlg, "@@@Control2") = .SelectedControl, GetStockObject(BLACK_BRUSH), GetStockObject(BLACK_BRUSH))
					Dim As HBrush PrevBrush = SelectObject(FHDc, Brush)
					SetROP2(FHDc, R2_NOT)
					Rectangle(FHDc, Ps.rcPaint.Left + 1, Ps.rcPaint.Top + 1, Ps.rcPaint.Right - 1, Ps.rcPaint.Bottom - 1)
					SelectObject(FHDc, PrevBrush)
					EndPaint(hDlg, @Ps)
					Return 0
					'or use WM_ERASEBKGND message
			#endif
				#ifdef __USE_GTK__
				Case GDK_MOTION_NOTIFY
					.FOverControl = Widget
				#else
				Case WM_MOUSEMOVE
					'.MouseMove(loWord(lParam), hiWord(lParam),wParam and &HFFFF )
					Select Case .IsDot(hDlg)
					Case 0 : SetCursor(crSizeNWSE)
					Case 1 : SetCursor(crSizeNS)
					Case 2 : SetCursor(crSizeNESW)
					Case 3 : SetCursor(crSizeWE)
					Case 4 : SetCursor(crSizeNWSE)
					Case 5 : SetCursor(crSizeNS)
					Case 6 : SetCursor(crSizeNESW)
					Case 7 : SetCursor(crSizeWE)
					End Select
					.FOverControl = hDlg
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_PRESS
				#else
				Case WM_LBUTTONDOWN
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y, x1, y1
					GetPosToClient(widget, .FDialogParent, @x, @y)
					GetPosToClient(.layoutwidget, .FDialogParent, @x1, @y1)
					.MouseDown(Event->button.x + x - x1, Event->button.y + y - y1, Event->button.state)
					Return True
				#else
					Dim P As Point
					P.X = LoWord(lParam)
					P.Y = HiWord(lParam)
					ScreenToClient .FDialog, @P
					.MouseDown(P.X, P.Y, wParam And &HFFFF )
					Return 0
				#endif
				#ifdef __USE_GTK__
				Case GDK_BUTTON_RELEASE
				#else
				Case WM_LBUTTONUP
				#endif
				#ifdef __USE_GTK__
					Dim As Integer x, y, x1, y1
					GetPosToClient(widget, .FDialogParent, @x, @y)
					GetPosToClient(.layoutwidget, .FDialogParent, @x1, @y1)
					.MouseUp(Event->button.x + x - x1, Event->button.y + y - y1, Event->button.state)
					Return True
				#else
					.MouseUp(LoWord(lParam), HiWord(lParam),wParam And &HFFFF )
					Return 0
					
				Case WM_NCHITTEST
					Return HTTRANSPARENT
				Case WM_KEYUP
				#endif
				#ifdef __USE_GTK__
				Case GDK_KEY_PRESS
				#else
				Case WM_KEYDOWN
				#endif
				#ifdef __USE_GTK__
					.KeyDown(Event->Key.keyval, Event->Key.state)
				#else
					.KeyDown(wParam, wParam And &HFFFF)
				#endif
				#ifndef __USE_GTK__
				Case WM_DESTROY
					RemoveProp(hDlg,"@@@Control")
					Return 0
				#endif
			End Select
		End With
	End If
	#ifndef __USE_GTK__
		Return DefWindowProc(hDlg, uMsg, wParam, lParam)
	#endif
End Function     

Sub Designer.RegisterDotClass(ByRef clsName As WString)
	#ifndef __USE_GTK__
		Dim As WNDCLASSEX wcls
		wcls.cbSize        = SizeOf(wcls)
		wcls.lpszClassName = @clsName
		wcls.lpfnWndProc   = @DotWndProc
		wcls.cbWndExtra   += 4
		wcls.hInstance     = instance
		RegisterClassEx(@wcls)
	#endif
End Sub

#ifdef __USE_GTK__
	Property Designer.Dialog As GtkWidget Ptr
		Return FDialog
	End Property
#else
	Property Designer.Dialog As HWND
		Return FDialog
	End Property
#endif

Sub Designer.PaintControl()
	If FDown AndAlso ((FCanInsert) OrElse (FCanMove = False AndAlso FCanSize = False)) Then
		#ifdef __USE_GTK__
			cairo_set_source_rgb(cr, 0.0, 0.0, 0.0)
			cairo_rectangle(cr, FBeginX, FBeginY, FNewX - FBeginX, FNewY - FBeginY)
			cairo_stroke(cr)
		#endif
	End If
	'cairo_fill(cr)
End Sub

#ifdef __USE_GTK__
	Function Dialog_Draw(widget As GtkWidget Ptr, cr As cairo_t Ptr, data1 As Any Ptr) As Boolean
		Dim As Designer Ptr Des = data1
		Des->cr = cr
		Des->DrawThis
		Des->PaintControl
		Return False
	End Function
	
	Function Dialog_ExposeEvent(widget As GtkWidget Ptr, Event As GdkEventExpose Ptr, data1 As Any Ptr) As Boolean
		Dim As cairo_t Ptr cr = gdk_cairo_create(Event->window)
		Dialog_Draw(widget, cr, data1)
		cairo_destroy(cr)
		Return False
	End Function
	
	Property Designer.Dialog(value As GtkWidget Ptr)
		If value <> FDialog Then
			UnHook
			FDialog = value
			If value <> 0 Then
				gtk_widget_set_can_focus(layoutwidget, True)
				'CreateDots(gtk_widget_get_parent(FDialog))
				If layoutwidget Then
					#ifdef __USE_GTK3__
						g_signal_connect(layoutwidget, "draw", G_CALLBACK(@Dialog_Draw), @This)
					#else
						g_signal_connect(layoutwidget, "expose-event", G_CALLBACK(@Dialog_ExposeEvent), @This)
					#endif
					'				Dim As GdkDisplay Ptr display = gdk_display_get_default ()
					'				Dim As GdkDeviceManager Ptr device_manager = gdk_display_get_device_manager (display)
					'				Dim As GdkDevice Ptr device = gdk_device_manager_get_client_pointer (device_manager)
					'				gtk_widget_set_device_enabled(layoutwidget, device, false)
					If FActive Then Hook
					'InvalidateRect(FDialog, 0, true)
				End If
			End If
		End If   
	End Property
#else
	Property Designer.Dialog(value As HWND)
		If value <> FDialog Then
			UnHook
			FDialog = value
			If value <> 0 Then
				'CreateDots(GetParent(FDialog))
				If FActive Then Hook
				InvalidateRect(FDialog, 0, True)
			End If
		End If   
	End Property
#endif

Property Designer.Active As Boolean
	Return FActive
End Property

Property Designer.Active(value As Boolean)
	If value <> FActive Then
		FActive = value
		If value Then
			Hook
		Else
			UnHook
			HideDots
		End If
		#ifndef __USE_GTK__
			InvalidateRect(FDialog, 0, True)
		#endif
	End If
End Property

Property Designer.ChildCount As Integer
	#ifndef __USE_GTK__
		GetChilds
	#endif
	Return FChilds.Count
End Property

Property Designer.ChildCount(value As Integer)
End Property

#ifndef __USE_GTK__
	Property Designer.Child(index As Integer) As HWND
		If index > -1 And index < FChilds.Count Then
			Return FChilds.Child[index]
		End If
		Return 0
	End Property
#endif

#ifndef __USE_GTK__
	Property Designer.Child(index As Integer,value As HWND)
	End Property
#endif

Property Designer.StepX As Integer
	Return FStepX
End Property

Property Designer.StepX(value As Integer)
	If value <> FStepX Then
		FStepX = value
		UpdateGrid
	End If   
End Property

Property Designer.StepY As Integer
	Return FStepY
End Property

Property Designer.StepY(value As Integer)
	If value <> FStepY Then
		FStepY = value
		UpdateGrid
	End If
End Property

Property Designer.DotColor As Integer
	#ifndef __USE_GTK__
		Dim As LOGBRUSH LB
		If GetObject(FDotBrush, SizeOf(LB), @LB) Then
			FDotColor = LB.lbColor
		End If
	#endif
	Return FDotColor
End Property

Property Designer.DotColor(value As Integer)
	If value <> FDotColor Then
		FDotColor = value
		#ifndef __USE_GTK__
			If FDotBrush Then DeleteObject(FDotBrush)
			FDotBrush = CreateSolidBrush(FDotColor)
			For i As Integer = 0 To 7
				InvalidateRect(FDots(0, i), 0, True)
			Next
		#endif
	End If
End Property

Property Designer.SnapToGrid As Boolean
	Return FSnapToGrid
End Property

Property Designer.SnapToGrid(value As Boolean)
	FSnapToGrid = value
End Property

Property Designer.ShowGrid As Boolean
	Return FShowGrid
End Property

Property Designer.ShowGrid(value As Boolean)
	FShowGrid = value
	#ifndef __USE_GTK__
		If IsWindow(FDialog) Then InvalidateRect(FDialog, 0, True)
	#endif
End Property

Property Designer.ClassName As String
	Return FClass
End Property

Property Designer.ClassName(value As String)
	FClass = value
End Property

Operator Designer.cast As Any Ptr
	Return @This
End Operator

Constructor Designer(ParentControl As Control Ptr)
	FStepX      = 10
	FStepY      = 10
	FShowGrid   = True
	FActive     = True
	FSnapToGrid = 1
	FDotSize 	= 10
	FDotColor 	= clBlack
	FSelDotColor = clBlue
	#ifdef __USE_GTK__
		FDialogParent = ParentControl->Widget
	#else
		FDialogParent = ParentControl->Handle
		FDotBrush   = CreateSolidBrush(FDotColor)
		FSelDotBrush   = CreateSolidBrush(FSelDotColor)
	#endif
	'FIsChild = True
	RegisterDotClass "DOT"
	WLet FClassName, "Designer"
	'OnHandleIsAllocated = @HandleIsAllocated
	'ChangeStyle WS_CHILD, True
	'FDesignMode = True
	'Base.Child             = Cast(Control Ptr, @This)
	CreateDots(ParentControl)
	#ifdef __USE_GTK__
		
	#else
		FPopupMenu  = CreatePopupMenu
		AppendMenu(FPopupMenu, MF_STRING, 10, @"Delete")
		AppendMenu(FPopupMenu, MF_SEPARATOR, -1, @"-")
		AppendMenu(FPopupMenu, MF_STRING, 12, @"Copy")
		AppendMenu(FPopupMenu, MF_STRING, 13, @"Cut")
		AppendMenu(FPopupMenu, MF_STRING, 14, @"Paste")
		AppendMenu(FPopupMenu, MF_SEPARATOR, -1, @"-")
		AppendMenu(FPopupMenu, MF_STRING, 16, @"Send To Back")
		AppendMenu(FPopupMenu, MF_SEPARATOR, -1, @"-")
		AppendMenu(FPopupMenu, MF_STRING, 18, @"Properties")
	#endif
End Constructor

'mnuDesigner.ImagesList = @imgList '<m>
mnuDesigner.Add(ML("Delete"), "", "Delete", @PopupClick)
mnuDesigner.Add("-")
mnuDesigner.Add(ML("Copy"), "Copy", "Copy", @PopupClick)
mnuDesigner.Add(ML("Cut"), "Cut", "Cut", @PopupClick)
mnuDesigner.Add(ML("Paste"), "Paste", "Paste", @PopupClick)
mnuDesigner.Add("-")
mnuDesigner.Add(ML("Send To Back"), "", "SendToBack", @PopupClick)
mnuDesigner.Add("-")
mnuDesigner.Add(ML("Properties"), "", "Properties", @PopupClick)

Destructor Designer
	UnHook
	#ifndef __USE_GTK__
		DeleteObject(FDotBrush)
		DeleteObject(FSelDotBrush)
		DeleteObject(FGridBrush)
		DestroyMenu(FPopupMenu)
	#endif
	DestroyDots
	'Delete DesignControl
	#ifndef __USE_GTK__
		UnregisterClass("DOT", instance)
	#endif
	For i As Integer = 0 To FLibs.Count - 1
		If FLibs.Object(i) <> 0 Then DyLibFree(FLibs.Object(i))
	Next
End Destructor
End Namespace
