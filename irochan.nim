{.link: "./irochan.res".}

import
  strutils, math, windows

const WM_NCMOUSELEAVE = 0x02A2;
const BUTTONCLASSNAME : LPCSTR = "BUTTON";
const STATICCLASSNAME : LPCSTR = "STATIC";
const ID_BTN_EXIT : HMENU = 100;
const ID_TXT_TEXT : HMENU = 101;
const TID_POLLMOUSE : WINUINT = 100;
const MOUSE_POLL_DELAY : WINUINT = 100;
const WINDOWNAME : LPCSTR = "irochan";

const APP_WIDTH = 160
const APP_HEIGHT = 82

let hInstance = GetModuleHandle(nil);

var hWndMain : HWND = 0;
var hwndCloseButton : HWND = 0;
var hwndText : HWND = 0;
var hButtonBrush : HBRUSH = 0;
var hMouseHook : HHOOK = 0;
var hdcScreen : HDC = 0;
var hFont : HFONT = 0;
var isTimerAlive : bool = false;
var colourRect = RECT(TopLeft : POINT(x : 6, y : 7), BottomRight : POINT(x : 37, y : 37));


proc RgbToHsv(red : int, green: int, blue: int) : auto =
    let r : float = float(red) / 255.0;
    let g : float = float(green) / 255.0;
    let b : float = float(blue) / 255.0;


    let rgb = [r, g, b];
    var max : float = max rgb;
    var min : float = min rgb;

    var h, s, v : float;
   
    v = max;
    
    let delta = max - min;

    if  max > 0:
        s = delta / max;
    else:
        return (0.0, -0.01, 0.0);    

    
    if r >= max :
        let difference = g - b;
        h = if (difference != 0.0 ) : (g - b) / delta
            else : 0.0;
            
    elif g >= max :
        h = 2.0 + (( b - r ) / delta);
    else :
        h = 4.0 + (( r - g ) / delta);

    h = h * 60;

    if h < 0 :
        h = h + 360;
    
    return (h, s, v);

proc IsMouseOverWindow (hWnd : HWND, point : POINT) : bool = 
    var rect : RECT;
    discard GetWindowRect(hWnd, addr rect);
    return PtInRect(addr rect, point) == 1;


proc UpdateColour () = 
    # Get the current cursor position
    var point : POINT;
    discard GetCursorPos(addr point);

    if IsMouseOverWindow (hWndMain, point):
        return;

    # Get the device context for the screen
    if hdcScreen == 0: 
        hdcScreen = GetDC(0);
    
    # Retrieve the color at that position
    let colour : COLORREF = GetPixel(hdcScreen, point.x, point.y);
    let brush : HBRUSH = CreateSolidBrush(colour);
    
    let hdc : HDC = GetDC(hWndMain);
    discard FillRect(hdc, colourRect, brush);
    discard DeleteObject(brush);
    discard ReleaseDC(hWndMain, hdc);

    let redValue = 0xff and (colour);
    let greenValue = 0xff and (colour shr 8);
    let blueValue = 0xff and (colour shr 16);
    
    
    let hexRep = toHex(blueValue, 2) & toHex(greenValue, 2) & toHex(redValue, 2);
    let htmlRep = toHex(redValue, 2) & toHex(greenValue, 2) & toHex(blueValue, 2);
    let hsv = RgbToHsv(redValue, greenValue, blueValue);

    

    let h = formatFloat(hsv[0], ffDecimal, 1);
    let s = formatFloat(hsv[1] * 100, ffDecimal, 1);
    let v = formatFloat(hsv[2] * 100, ffDecimal, 1);

    let text : string = "pixel at [" & $point.x & ", " & $point.y & "]\L" & 
                        "HEX 0x" & hexRep & "\L" &
                        "HTML #" & htmlRep & "\L" &
                        "RGB (" & $redValue & "," & $greenValue & "," & $blueValue & ")\L" &
                        "HSV (" & h & "," & s & "," & v & ")";

    let cString : cstring = text;

    discard SendMessage(hwndText, WM_SETTEXT, 0, cast[LPARAM](cString));

proc MouseProc(nCode: int32; wParam: WPARAM; lParam: LPARAM) : LRESULT {.stdcall procvar.} = 
    if nCode == HC_ACTION:
        case wParam:
        of WM_MOUSEMOVE, WM_NCMOUSEMOVE:
            if isTimerAlive :
                discard KillTimer (hWndMain, TID_POLLMOUSE);
                isTimerAlive = false;

        else:
            discard;

    return CallNextHookEx(hMouseHook, nCode, wParam, lParam);

# Main Window Procedure
proc WndProc(hWnd: HWND; msg: WINUINT; wParam: WPARAM; lParam: LPARAM) : LRESULT {.stdcall procvar.}  = 

    case msg:
    of WM_CREATE:
        # hMouseHook = SetWindowsHookEx(WH_MOUSE, MouseProc, 0, GetCurrentThreadId());

        hwndCloseButton = CreateWindow (
                       BUTTONCLASSNAME,          # The class name required is button
                       "x",                  # the caption of the button
                       WS_CHILD or WS_VISIBLE or BS_FLAT, # the styles
                       24, 51,                                  # the left and top co-ordinates
                       14, 14,                              # width and height
                       hWnd,                                 # parent window handle
                       ID_BTN_EXIT,                   # the ID of your button
                       hInstance,                            # the instance of your application
                       nil);                                # extra bits you dont really need

        hwndText = CreateWindow (
                       STATICCLASSNAME,
                       nil,
                       WS_CHILD or WS_VISIBLE or SS_LEFT,
                       44, 5,                                   # the left and top co-ordinates
                       110, 70,                                 # width and height
                       hWnd,                                    # parent window handle
                       ID_TXT_TEXT,                             # the ID of your button
                       hInstance,                               # the instance of your application
                       nil);                                    # extra bits you dont really need

        hFont = CreateFont(12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "Helvetica");

        discard PostMessage(hWndText, WM_SETFONT, hFont, 1);

        discard SetTimer(hWnd, TID_POLLMOUSE, MOUSE_POLL_DELAY, nil);
        isTimerAlive = true;

        return 0;

    of WM_CTLCOLORBTN:
        let hdcButton : HDC = wParam;
        let hWndButton = lParam;

        if hWndButton == hwndCloseButton:
            if hButtonBrush == 0:
                hButtonBrush = GetStockObject(WHITE_BRUSH);

            discard SetBkColor(hdcButton, RGB(255,255,255));

        return hButtonBrush;
    
    of WM_CTLCOLORSTATIC:
        return GetStockObject(WHITE_BRUSH);

    of WM_COMMAND:
        let event = HIWORD(cast[int32](wParam));
        let id : HMENU = LOWORD(cast[int32](wParam));
        case event:
        of BN_CLICKED:
            case id:
            of ID_BTN_EXIT:
                discard SendMessage(hWndMain, WM_CLOSE, 0, 0);
                return 0;
            else:
                discard;
        else:
            discard;

    of WM_NCHITTEST:
        let hit : LRESULT = DefWindowProc(hWnd, msg, wParam, lParam);
        if hit == HTCLIENT:
            return HTCAPTION;
        else:
            return hit;
            
    of WM_PAINT:
        var ps : PAINTSTRUCT;
        let hdc : HDC = BeginPaint(hWnd, addr ps);

        discard FillRect(hdc, ps.rcPaint, (HBRUSH) (COLOR_WINDOW + 1));
        discard FillRect(hdc, colourRect, (HBRUSH) (COLOR_WINDOWTEXT + 1));

        discard EndPaint(hdc, addr ps);

    of WM_TIMER:
        UpdateColour();

    of WM_DESTROY:
        discard KillTimer(hwnd, TID_POLLMOUSE);
        isTimerAlive = false;

        if hMouseHook != 0:
            discard UnhookWindowsHookEx(hMouseHook);

        if hWndCloseButton != 0:
            discard DeleteObject (hWndCloseButton);

        if hwndText != 0:
            discard DeleteObject (hwndText);

        if hdcScreen != 0:
            discard DeleteObject (hdcScreen);

        if hFont != 0:
            discard DeleteObject (hFont);
        
        PostQuitMessage(0);
        quit();


    else:
        discard;

    return DefWindowProc(hWnd, msg, wParam, lParam);

var wndClass : WNDCLASS;

const CLASSNAME : LPCSTR = "MYWINDOWCLASS";

wndClass.lpfnWndProc   = WndProc;
wndClass.hInstance     = hInstance;
wndClass.lpszClassName = CLASSNAME;


var windowStyles : DWORD = WS_OVERLAPPEDWINDOW or WS_BORDER or WS_POPUP or WS_CLIPSIBLINGS;
windowStyles = windowStyles and not (WS_DLGFRAME or WS_THICKFRAME or WS_MINIMIZE or WS_MAXIMIZE or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX);

discard RegisterClassA(addr wndClass);

let centerX = GetSystemMetrics(SM_CXSCREEN) div 2
let centerY = GetSystemMetrics(SM_CYSCREEN) div 2

hWndMain = CreateWindowEx(
        WS_EX_TOPMOST,              # Optional window styles.
        CLASS_NAME,                 # Window class
        WINDOWNAME,                 # Window text
        windowStyles,               # Window style

        # Size and position
        centerX - (APP_WIDTH div 2), 
        centerY - (APP_HEIGHT div 2)
        , APP_WIDTH, APP_HEIGHT,

        cast[HWND](nil),        # Parent window    
        cast[HMENU](nil),       # Menu
        hInstance,              # Instance handle
        cast[LPVOID](nil)       # Additional application data
        );

if hWndMain == cast[HWND](nil):
    discard MessageBox(0, "Could not create Window!", "Error", MB_OK or MB_ICONERROR)
    quit(QuitFailure);

discard ShowWindow(hWndMain, SW_SHOWDEFAULT);
discard UpdateWindow(hWndMain);

var msg : MSG;

while GetMessage(addr msg, cast[HWND](nil), cast[WINUINT](0), cast[WINUINT](0)) != 0 :
    discard TranslateMessage(addr msg);
    discard DispatchMessage(addr msg);
quit();
