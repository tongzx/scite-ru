// Небольшая страховка, т.к. используем только "узкострочные" функции
#if defined(UNICODE) && defined(_UNICODE)
#  undef UNICODE
#  undef _UNICODE
#  define RESTOREUNICODENESS 3
#elseif  defined(UNICODE)
#  undef UNICODE
#  define RESTOREUNICODENESS 2
#elseif  defined(_UNICODE)
#  undef _UNICODE
#  define RESTOREUNICODENESS 1
#endif

#include <windows.h>
#include "resource.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

//------------------------------------------------------------------------------
struct Rect : public RECT {
	Rect() {
		left = top = right = bottom = 0;
	}
	Rect(int Left, int Top, int Right, int Bottom) {
		left   = Left;
		top    = Top;
		right  = Right;
		bottom = Bottom;
	}
	Rect(const Rect &rc) {
		left   = rc.left;
		top    = rc.top;
		right  = rc.right;
		bottom = rc.bottom;
	}
	Rect& operator = (const Rect &rc) {
		if (this != &rc) {
			left   = rc.left;
			top    = rc.top;
			right  = rc.right;
			bottom = rc.bottom;
		}
		return *this;
	}
	Rect& operator = (const Rect *rc) {
		if (this != rc) {
			left   = rc->left;
			top    = rc->top;
			right  = rc->right;
			bottom = rc->bottom;
		}
		return *this;
	}
	int width() const
		{ return right - left; }
	int height() const
		{ return bottom - top; }
	void GetWindowRect(HWND hwnd) {
			::GetWindowRect(hwnd, this);
		}
	void GetWindowRect(int ctrlID, HWND parent) {
			::GetWindowRect(::GetDlgItem(parent, ctrlID), this);
		}
	void GetClientRect(HWND hwnd) {
			::GetClientRect(hwnd, this);
		}
	void MapPoints(HWND hwnd) {
			::MapWindowPoints(0, hwnd, static_cast<POINT*>(static_cast<void*>(this)), 2);
		}
	void MoveWindow(HWND hwnd, int left, int top, bool repaint=false) {
			::MoveWindow(hwnd, left, top, width(), height(), repaint? 1:0);
		}
	void MoveWindow(int ctrlID, HWND parent, int left, int top, bool repaint=false) {
			::MoveWindow(GetDlgItem(parent, ctrlID), left, top, width(), height(), repaint? 1:0);
		}
	void AdjustWindowRect(HWND hwnd, bool hasMenu=false) {
			::AdjustWindowRect(this, GetWindowLongPtr(hwnd, GWL_STYLE) & ~WS_OVERLAPPED, hasMenu? 1:0);
		}
};

//------------------------------------------------------------------------------


int GetClientWidth(HWND hwnd)
{
	Rect rc;
	::GetClientRect(hwnd, &rc);
	return rc.width();
}

int GetClientWidth(int ctrlID, HWND parent)
{
	Rect rc;
	::GetClientRect(::GetDlgItem(parent, ctrlID), &rc);
	return rc.width();
}

int GetWindowWidth(HWND hwnd)
{
	Rect rc;
	::GetWindowRect(hwnd, &rc);
	return rc.width();
}

int GetWindowWidth(int ctrlID, HWND parent)
{
	Rect rc;
	::GetWindowRect(::GetDlgItem(parent, ctrlID), &rc);
	return rc.width();
}

int GetWindowHeight(int ctrlID, HWND parent)
{
	Rect rc;
	::GetWindowRect(::GetDlgItem(parent, ctrlID), &rc);
	return rc.height();
}

//------------------------------------------------------------------------------
class InputBox {
	typedef struct {
		InputBox *self;
		bool isFirst;
		Rect rc;
	} DlgData;

	enum { MAX_SHORT_STRING=128, MAX_MIDDLE_STRING=512, MAX_LONG_STRING=1024 };

public:
	InputBox(const char *Caption, const char *Prompt, const char *Value,
		int CharMinCount, int OnChar, int OnEnter, lua_State* L);
	~InputBox();
	int  ShowModal();
	const char *Text() const;

private:

	InputBox();

	int  PrepareTextOut(HWND hdlg);
	BOOL OutText(HDC hdc);
	void PrepareEdit(HWND hdlg);
	void Layout(HWND hdlg);
	void AdjustWidth(int ctrlID, HWND hdlg, int width);
	void AdjustWidth(int ctrlID, HWND hdlg);
	void AdjustDlg(HWND hdlg);
	void MoveY(int ctrlID, HWND hdlg, int dy);
	void CenterButtons(HWND hdlg);
	void CalcDlgMinWidth(HWND hdlg);
	static BOOL CALLBACK EditHandler(HWND, UINT, WPARAM, LPARAM);
	static BOOL CALLBACK DlgHandler(HWND, UINT, WPARAM, LPARAM);

private:

	DlgData data;

	char editText[MAX_MIDDLE_STRING];  // введённый пользователем текст
	char caption[MAX_SHORT_STRING];    // заголовок окна диалога
	char prompt[MAX_LONG_STRING];      // многострочная надпись над полем ввода

	int marginX;       // гор. отступ от края окна
	int marginY;       // верт. отступ от края окна
	int spacing;       // верт. интервал между полем ввода и кнопками
	int btnSpacing;    // гориз. интервал между кнопками
	int stcDy;
	int charMinCount;  // ширина поля ввода в усреднённых символах
	int minWidth;      // мин. ширина окна (в пикселах)
	HICON smallIcon;
	HICON bigIcon;
	lua_State *luaState;
	int onChar;
	int onEnter;
};

//------------------------------------------------------------------------------
// Вычисляет прибл. ширину строки символов в пикселах по кол-ву этих символов
//------------------------------------------------------------------------------
int CalcAverWidth(HWND hwnd, int charCount)
{
	// Ширина = (усреднённая ширина символа) * (мин. кол-во символов)
	TEXTMETRIC mtr;
	HDC hdc = GetDC(hwnd);
	SelectObject(hdc, GetStockObject(DEFAULT_GUI_FONT));
	GetTextMetrics(hdc, &mtr);
	ReleaseDC(hwnd, hdc);
	return mtr.tmAveCharWidth*charCount;
}

//------------------------------------------------------------------------------
// Вычисляет ограничения на мин. ширину окна
//------------------------------------------------------------------------------
void InputBox::CalcDlgMinWidth(HWND hdlg)
{
	int stc = GetWindowWidth(IDC_PROMPTTEXT, hdlg);
	int edc = GetWindowWidth(IDC_EDITTEXT, hdlg);
	int btn = GetWindowWidth(IDOK, hdlg);

	minWidth = CalcAverWidth(GetDlgItem(hdlg, IDC_EDITTEXT), charMinCount);
	minWidth = max(minWidth, max(stc, edc));
	minWidth = max(minWidth, 2*btn + btnSpacing);

	Rect rc;
	rc.GetClientRect(hdlg);
	rc.right = minWidth + 2*marginX;
	rc.AdjustWindowRect(hdlg);
	minWidth = rc.width();
}

//------------------------------------------------------------------------------
// Изменяет ширину контрола на заданную
//------------------------------------------------------------------------------
void InputBox::AdjustWidth(int ctrlID, HWND hdlg, int width)
{
	HWND hctrl = GetDlgItem(hdlg, ctrlID);
	Rect rc;
	rc.GetWindowRect(hctrl);
	rc.MapPoints(hdlg);
	SetWindowPos(hctrl, 0, 0, 0, width, rc.height(), SWP_NOMOVE|SWP_NOZORDER);
}

//------------------------------------------------------------------------------
// Подгоняет ширину контрола под ширину окна диалога
//------------------------------------------------------------------------------
void InputBox::AdjustWidth(int ctrlID, HWND hdlg)
{
	Rect rc, rcCtrl;
	rc.GetClientRect(hdlg);
	HWND hctrl = GetDlgItem(hdlg, ctrlID);
	rcCtrl.GetWindowRect(hctrl);
	rcCtrl.MapPoints(hdlg);
	SetWindowPos(hctrl, 0, marginX, rcCtrl.top,
		rc.width() - 2*marginX, rcCtrl.height(), SWP_NOZORDER);
}

//------------------------------------------------------------------------------
// Подгоняет размеры окна диалога и его элементов друг к другу
//------------------------------------------------------------------------------
void InputBox::AdjustDlg(HWND hdlg)
{
	Rect rcStc, rcEdc, rcOk;
	rcStc.GetWindowRect(IDC_PROMPTTEXT, hdlg);
	rcEdc.GetWindowRect(IDC_EDITTEXT, hdlg);
	rcOk.GetWindowRect(IDOK, hdlg);
	rcOk.MapPoints(hdlg);

	// Фиксируем мин. ширину окна диалога
	CalcDlgMinWidth(hdlg);

	// Настраиваем размеры окна диалога
	Rect rc(0, 0, minWidth, rcOk.bottom + marginY);
	rc.AdjustWindowRect(hdlg);
	SetWindowPos(hdlg, 0, 0, 0, rc.width(), rc.height(), SWP_FRAMECHANGED|SWP_NOMOVE);
	minWidth = GetWindowWidth(hdlg);

	// Подгоняем ширину контролов под ширину окна
	AdjustWidth(IDC_PROMPTTEXT, hdlg);
	AdjustWidth(IDC_EDITTEXT, hdlg);
}

//------------------------------------------------------------------------------
// Смещает контролы по высоте
//------------------------------------------------------------------------------
void InputBox::MoveY(int ctrlID, HWND hdlg, int y)
{
	Rect rc;
	rc.GetWindowRect(ctrlID, hdlg);
	rc.MapPoints(hdlg);
	rc.MoveWindow(ctrlID, hdlg, rc.left, y, true);
}

//------------------------------------------------------------------------------
// Центрирует кнопки по горизонтали, делает их равного размера
//------------------------------------------------------------------------------
void InputBox::CenterButtons(HWND hdlg)
{
	// Кнопка Ok для упрощения всегда помещается слева.
	// Размеры и положение по вертикали берутся из таковых для кнопки Ok

	HWND hOk = GetDlgItem(hdlg, IDOK);
	HWND hCancel = GetDlgItem(hdlg, IDCANCEL);
	Rect rcOk;
	rcOk.GetWindowRect(hOk);
	rcOk.MapPoints(hdlg);

	// вычисляем требуемые смещения
	int okX = (GetClientWidth(hdlg) - 2*rcOk.width() - btnSpacing)/2;
	int cancelX = okX + rcOk.width() + btnSpacing;

	// центрируем ряд с кнопками
	rcOk.MoveWindow(hOk, okX, rcOk.top, true);
	rcOk.MoveWindow(hCancel, cancelX, rcOk.top, true);
}

//------------------------------------------------------------------------------
// Готовит static для вывода многострочного текста.
//------------------------------------------------------------------------------
int InputBox::PrepareTextOut(HWND hdlg)
{
	if (!prompt || ! *prompt)
		return 0;

	HWND hctrl = GetDlgItem(hdlg, IDC_PROMPTTEXT);

	SIZE maxSize = { 0 };
	HDC hdc = GetDC(hctrl);
	SelectObject(hdc, GetStockObject(DEFAULT_GUI_FONT));
	GetTextExtentPoint32 (hdc, prompt, lstrlen(prompt), &maxSize);
	maxSize.cx = 0;

	SIZE size = { 0 };
	int lnCount = 1;
	const char *prev = prompt;
	const char *p = prompt;

	for (; *p; ++p) {
		if (*p == '\r' || *p == '\n') {
			GetTextExtentPoint32 (hdc, prev, p-prev, &size);
			maxSize.cx = max(size.cx, maxSize.cx);
			prev = p + 1;
			lnCount++;
		}
	}

	if (prev != p) {
		GetTextExtentPoint32 (hdc, prev, p-prev, &size);
		maxSize.cx = max(size.cx, maxSize.cx);
	}

	ReleaseDC(hdlg, hdc);

	// Вычислим высоту надписи с интерлиньяжем в 1.1.
	int ext = maxSize.cy/10;
	stcDy = maxSize.cy + ext;
	maxSize.cy = maxSize.cy*lnCount + (lnCount-1)*ext;

	// Устанавливаем размеры надписи
	SetWindowPos(hctrl, 0, 0, 0, maxSize.cx, maxSize.cy, SWP_NOMOVE);

	// Вернём высоту контрола плюс дополнительный интервал
	return maxSize.cy + 4*ext;
}

//------------------------------------------------------------------------------
// Выводит текст надписи
//------------------------------------------------------------------------------
BOOL InputBox::OutText(HDC hdc)
{
	SelectObject(hdc, GetStockObject(DEFAULT_GUI_FONT));
	SelectObject(hdc, reinterpret_cast<HBRUSH>(COLOR_BTNFACE+1));
	SetBkMode(hdc, TRANSPARENT);
	const char *prev = prompt;
	const char *p = prompt;
	int y = 0;

	for (; *p; ++p) {
		if (*p == '\r' || *p == '\n') {
			TextOut(hdc, 0, y, prev, p-prev);
			prev = p + 1;
			y += stcDy;
		}
	}
	if (prev != p)
		TextOut(hdc, 0, y, prev, p-prev);

	return reinterpret_cast<BOOL>(GetStockObject(NULL_BRUSH));
}

//------------------------------------------------------------------------------
// Готовит edit для ввода текста.
//------------------------------------------------------------------------------
void InputBox::PrepareEdit(HWND hdlg)
{
	HWND hctrl = GetDlgItem(hdlg, IDC_EDITTEXT);

	HDC hdc = GetDC(hctrl);
	SelectObject(hdc, GetStockObject(DEFAULT_GUI_FONT));

	SIZE size = { 0 };
	Rect rc;
	rc.GetClientRect(hctrl);
	rc.right = 0;

	int len = lstrlen(editText);
	if (len) {
		GetTextExtentPoint32 (hdc, editText, len, &size);
		if (rc.right < size.cx)
			rc.right = size.cx;
	}

	TEXTMETRIC tm = { 0 };
	GetTextMetrics(hdc, &tm);
	if (rc.height() < tm.tmHeight)
		rc.bottom = rc.top + tm.tmHeight;

	rc.AdjustWindowRect(hctrl);
	SetWindowPos(hctrl, 0, 0, 0, rc.width(), rc.height(), SWP_NOZORDER|SWP_NOMOVE);

	ReleaseDC(hdlg, hdc);
}

//------------------------------------------------------------------------------
// Размещает элементы диалога
//------------------------------------------------------------------------------
void InputBox::Layout(HWND hdlg)
{
	// Выведем заголовок диалога
	SetWindowText(hdlg, caption);

	// Подготовим надпись
	int editY =  marginY + PrepareTextOut(hdlg);

	// Подготовим поле ввода
	PrepareEdit(hdlg);

	// Позиционируем контролы по вертикали
	MoveY(IDC_PROMPTTEXT, hdlg, marginY);
	MoveY(IDC_EDITTEXT, hdlg, editY);
	editY += GetWindowHeight(IDC_EDITTEXT, hdlg) + spacing;
	MoveY(IDOK, hdlg, editY);
	MoveY(IDCANCEL, hdlg, editY);

	// Окончательная подгонка размеров
	AdjustDlg(hdlg);

	// Центрируем кнопки
	CenterButtons(hdlg);
}

//------------------------------------------------------------------------------
// Выводит текст на консоль SciTE.
// msg == NULL означает, что текст лежит на вершине стека.
//------------------------------------------------------------------------------
void OutputMessage(lua_State *L, const char *msg=0)
{
	char *txt;
	if (msg) {
		txt = new char[lstrlen(msg) + 2];
		lstrcpy(txt, msg);
	} else {
		if (!lua_isstring(L, -1))
			return;
		txt = new char[lstrlen(lua_tostring(L, -1)) + 2];
		lstrcpy(txt, lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	lstrcat(txt, "\n");

	lua_getglobal(L, "output");
	lua_getfield(L, -1, "AddText");
	lua_insert(L, -2);
	lua_pushstring(L, txt);
	delete[] txt;
	lua_pcall(L, 2, 0, 0);
}

//------------------------------------------------------------------------------
// Передаёт пользовательской функции on_char вводимый текст для проверки
//------------------------------------------------------------------------------
bool IsInputValid(lua_State *L, char ch, const char *str, int checker)
{
	if (checker) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, checker);
		lua_pushlstring(L, &ch, 1);
		lua_pushstring(L, str);
		if (lua_pcall(L, 2, 1, 0)) {
			OutputMessage(L);
			lua_pushboolean(L, 1);
		}
		return lua_toboolean(L, -1) != 0;
	}
	return true;
}

//------------------------------------------------------------------------------
// Передаёт пользовательской функции on_enter текст для окончательной проверки
//------------------------------------------------------------------------------
bool IsInputValid(lua_State *L, const char *str, int checker)
{
	if (checker) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, checker);
		lua_pushstring(L, str);
		if (lua_pcall(L, 1, 1, 0)) {
			OutputMessage(L);
			lua_pushboolean(L, 1);
		}
		return lua_toboolean(L, -1) != 0;
	}
	return true;
}

//------------------------------------------------------------------------------
typedef LRESULT (CALLBACK * WNDPROC)(HWND, UINT, WPARAM, LPARAM);
WNDPROC originalEditHandler = 0;

//------------------------------------------------------------------------------
// Обработчик сообщений поля ввода
//------------------------------------------------------------------------------
BOOL CALLBACK InputBox::EditHandler(HWND hctrl, UINT msg, WPARAM wParam, LPARAM lParam)
{
	InputBox *self = reinterpret_cast<InputBox*>(GetWindowLongPtr(hctrl, GWLP_USERDATA));

	switch (msg) {
		case WM_CHAR:
		{
			unsigned char ch = static_cast<unsigned char>(wParam);
			if (ch != VK_BACK) {
				int bSel = 0;
				int eSel = 0;
				char str[sizeof(self->editText)];
				char tail[sizeof(self->editText)];
				tail[0] = '\0';
				int len = GetWindowText(hctrl, str, sizeof(self->editText));

				if (len) {
					SendMessage(hctrl, EM_GETSEL, reinterpret_cast<WPARAM>(&bSel),
						reinterpret_cast<LPARAM>(&eSel));
					lstrcpy(tail, str+eSel);
				}

				str[bSel] = ch;
				str[bSel+1] = '\0';
				lstrcat(str, tail);

				if (!IsInputValid(self->luaState, ch, str, self->onChar)) {
					return 0;
				}
			}
		}
	}
	return CallWindowProc(originalEditHandler, hctrl, msg, wParam, lParam);
}

//------------------------------------------------------------------------------
// Обработчик сообщений окна диалога
//------------------------------------------------------------------------------
BOOL CALLBACK InputBox::DlgHandler(HWND hdlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
	if (msg == WM_INITDIALOG) {

		// Свяжем этот экземляр окна с объектом типа InputBox, создавшим его
		InputBox *self = reinterpret_cast<InputBox*>(lParam);
		self->data.self = self;
		self->data.isFirst = true;
		SetWindowLongPtr(hdlg, DWLP_USER, reinterpret_cast<LONG_PTR>(&self->data));

		// Делаем подкласс поля ввода с целью обработки вводимых символов
		HWND hedit = GetDlgItem(hdlg, IDC_EDITTEXT);
		originalEditHandler = reinterpret_cast<WNDPROC>(
			SetWindowLongPtr(hedit, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(EditHandler))
		);
		SetWindowLongPtr(hedit, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));

		WPARAM font = reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT));
		SendMessage(GetDlgItem(hdlg, IDC_PROMPTTEXT), WM_SETFONT, font, FALSE);
		SendMessage(hedit, WM_SETFONT, font, FALSE);

		// Разместим в окне элементы диалога
		self->Layout(hdlg);

		// Помещаем текст в поле ввода
		SetDlgItemText(hdlg, IDC_EDITTEXT, self->editText);

		// Ограничиваем допустимый размер вводимого текста
		SendMessage(GetDlgItem(hdlg, IDC_EDITTEXT), EM_SETLIMITTEXT, sizeof(self->editText)-1, 0);

		// Центрируем диалог на экране
		Rect rcDt, rcDlg;
		rcDt.GetWindowRect(GetDesktopWindow());
		rcDlg.GetWindowRect(hdlg);
		rcDlg.MoveWindow(hdlg, rcDt.left + (rcDt.width() - rcDlg.width())/2,
			rcDt.top + (rcDt.height() - rcDlg.height())/2);

		return TRUE;

	} else {

		DlgData  *data = reinterpret_cast<DlgData*>(GetWindowLongPtr(hdlg, DWLP_USER));
		InputBox *self = 0;
		Rect     *strc = 0;

		if (data) {
			self = data->self;
			strc = &data->rc;
		}

		switch (msg) {
			case WM_COMMAND:
			{
				switch (LOWORD(wParam)) {
					case IDOK:
						if (!GetDlgItemText(hdlg, IDC_EDITTEXT, self->editText, MAX_MIDDLE_STRING)) {
							self->editText[0] = '\0';
						}

						if (!IsInputValid(self->luaState, self->editText, self->onEnter)) {
							return TRUE;
						}
					case IDCANCEL:
						EndDialog(hdlg, wParam);
						return TRUE;
				}
				break;
			}

			case WM_GETICON:
				// Возвращаем загруженные ранее иконки взамен стандартных
				switch (wParam) {
					case ICON_BIG:
						SetWindowLongPtr(hdlg, DWL_MSGRESULT, reinterpret_cast<LONG_PTR>(self->bigIcon));
						break;
					case ICON_SMALL:
					case 2 /*ICON_SMALL2*/:
						SetWindowLongPtr(hdlg, DWL_MSGRESULT, reinterpret_cast<LONG_PTR>(self->smallIcon));
						break;
					default:
						return FALSE;
				}
				return TRUE;

			case WM_CTLCOLORSTATIC:
			{
				// Выводим надпись
				HWND hctrl = reinterpret_cast<HWND>(lParam);
				if (hctrl == GetDlgItem(hdlg, IDC_PROMPTTEXT)) {
					// Всегда возвращаем NULL_BRUSH, чтобы надпись не стиралась
					return self->OutText(reinterpret_cast<HDC>(wParam));
				}
				break;
			}

			case WM_SIZING:
			{
				// Позволим пользователю в установленных пределах изменять ширину окна

				Rect *rc = reinterpret_cast<Rect*>(lParam);

				if (!data->isFirst) {
					switch (wParam) {
						case WMSZ_BOTTOM:
						case WMSZ_BOTTOMLEFT:
						case WMSZ_BOTTOMRIGHT:
							if (rc->bottom != strc->bottom)
								rc->bottom = strc->bottom;
							break;
						case WMSZ_TOP:
						case WMSZ_TOPLEFT:
						case WMSZ_TOPRIGHT:
							if (rc->top != strc->top)
								rc->top = strc->top;
							break;
					}

					int newWidth = rc->width();

					switch (wParam) {
						case WMSZ_RIGHT:
						case WMSZ_TOPRIGHT:
						case WMSZ_BOTTOMRIGHT:
						{
							if (newWidth < self->minWidth) {
								newWidth = self->minWidth;
								rc->right = rc->left + self->minWidth;
							}
						}
						case WMSZ_LEFT:
						case WMSZ_TOPLEFT:
						case WMSZ_BOTTOMLEFT:
						{
							if (newWidth < self->minWidth) {
								newWidth = self->minWidth;
								rc->left = rc->right - self->minWidth;
							}
						}
					}

					*strc = *rc;
					return TRUE;
				}
				break;
			}

			case WM_SIZE:
			{
				// Подгоняем размеры и позицию контролов под изменения

				int dx = strc->width();
				GetWindowRect(hdlg, strc);
				dx = strc->width() - dx;

				if (data->isFirst) {
					data->isFirst = false;
				} else if (wParam == SIZE_RESTORED) {
					self->AdjustWidth(IDC_PROMPTTEXT, hdlg);
					self->AdjustWidth(IDC_EDITTEXT, hdlg);
					self->CenterButtons(hdlg);
				}
				return TRUE;
			}

			case WM_MOVE:
			{
				// Запомним новую позицию окна
				strc->GetWindowRect(hdlg);
				return TRUE;
			}
		}
	}
	return FALSE;
}

//------------------------------------------------------------------------------
InputBox::InputBox(const char *Caption, const char *Prompt, const char *Value,
	int CharMinCount, int OnChar, int OnEnter, lua_State* L)
	:
	marginX      (10),
	marginY      (10),
	spacing      (15),
	btnSpacing   (10),
	stcDy        (0),
	charMinCount (CharMinCount),
	luaState     (L),
	minWidth     (0),
	onChar       (OnChar),
	onEnter      (OnEnter)
{
	lstrcpyn(editText, Value, sizeof(editText));
	lstrcpyn(caption, Caption, sizeof(caption));
	lstrcpyn(prompt, Prompt, sizeof(prompt));

	smallIcon = static_cast<HICON>(
		LoadImage(GetModuleHandle(0), "SCITE", IMAGE_ICON,
			GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON),
			LR_DEFAULTCOLOR));
	bigIcon = static_cast<HICON>(
		LoadImage(GetModuleHandle(0), "SCITE", IMAGE_ICON,
			48, 48, LR_DEFAULTCOLOR));
}

//------------------------------------------------------------------------------
InputBox::~InputBox()
{
	DestroyIcon(smallIcon);
	DestroyIcon(bigIcon);
	if (onChar)
		luaL_unref(luaState, LUA_REGISTRYINDEX, onChar);
	if (onEnter)
		luaL_unref(luaState, LUA_REGISTRYINDEX, onEnter);
}

//------------------------------------------------------------------------------
const char *InputBox::Text() const
{
	return editText;
}

//------------------------------------------------------------------------------
int InputBox::ShowModal()
{
	int result = DialogBoxParam(GetModuleHandle("shell.dll"), "IBOX_DLG",
		GetDesktopWindow(), DlgHandler, reinterpret_cast<LPARAM>(this));
	if (result == -1) {
		// Вообще-то, это означает, что произошла какая-то ошибка,
		// но мы сделаем вид, что всё Ок: будто бы нажата Cancel
		return IDCANCEL;
	}
	return result;
}

//------------------------------------------------------------------------------
// "Костыль", приделанный во время отладки. 
// Пока оставим: похоже, пришёлся впору. ;)
//------------------------------------------------------------------------------
class StackBalancer {
	StackBalancer();
	StackBalancer(const StackBalancer&);
	lua_State * L;
	int n;
	bool purged;
public:
	StackBalancer(lua_State *ls)
		: L(ls), n(lua_gettop(ls)), purged(false)
		{ }
	~StackBalancer()
		{ Purge(); }
	void Purge()
	{
		int dn = lua_gettop(L) - n;
		if (!purged && dn > 0) {
			lua_pop(L, dn);
			n = lua_gettop(L);
			purged = true;
		}
	}
};

// Helpers для извлечения элементов таблицы

class LuaTable {
	lua_State *L;
	int table;
private:
	LuaTable();
	LuaTable(const LuaTable&);
	void getKey(const char *key)
	{
		lua_checkstack(L, 2);
		lua_pushstring(L, key);
		lua_rawget(L, table);
	}
public:
	LuaTable(lua_State *ls, int tbl)
		: L(ls), table(tbl)
	{ }
	// Строка помещается на вершину стека и возвращается указатель на неё
	const char *GetString(const char *key, const char *defaultValue="")
	{
		getKey(key);
		const char *res = lua_tostring(L, -1);
			
		if (res) return res;
		else     return defaultValue;
	}
	// Возвращается ссылка на функцию
	int GetFunction(const char *key)
	{
		getKey(key);
		if (lua_isfunction(L, -1)) {
			return luaL_ref(L, LUA_REGISTRYINDEX);
		}
		return 0;
	}
	// Возвращается целочисленное значение
	int GetInt(const char *key, int defaultValue)
	{
		StackBalancer sb(L);
		getKey(key);
		if (lua_isnumber(L, -1))
			return luaL_checkint(L, -1);
		return defaultValue;
	}
};

/*
--------------------------------------------------------------------------------
  Функция
     shell.showinputbox
  Параметры
     caption
         Текст заголовка окна.
         Значение по умолчанию: "InputBox".
     prompt
         Надпись над полем ввода (строки должны разделяться '\r' или '\n').
         Значение по умолчанию: "Enter:".
     value
         Текст, помещаемый в поле ввода.
         Значение по умолчанию: "" (пустая строка).
     on_char
         Пользовательская функция-контролёр ВВОДИМОЙ строки.
         Вызывается каждый раз, когда поступает новый символ
         (однако, НЕ вызывается при нажатии на Backspace, удалениях и т.п).
         Получает только что введённый символ (этого символа ещё нет ни
            на экране, ни в строке ввода) и весь текст из строки ввода
             в том виде, в каком он будет ПОСЛЕ принятия этого символа.
         Должна вернуть true, если изменения принимаются, иначе - false.
         Значение по умолчанию: nil (никаких ограничений на ввод).
     on_enter
         Пользовательская функция-контролёр ВВЕДЁННОЙ строки.
         Вступает в действие после нажатия на Enter или Ok.
         Не вызывается при отмене ввода.
         Получает введённую пользователем строку.
         Должна вернуть true, если строка принимается, иначе - false.
         В последнем случае процесс ввода продолжается дальше.
         Значение по умолчанию: nil (контроль отсутствует).
     width
         Ширина поля ввода в условных (усреднённых символах).
         Значение по умолчанию: 20.
 Результат
     Введённая строка или nil, если ввод был отменён.

 ВНИМАНИЕ!
     Все параметры -- именованные и передаются как элементы таблицы.
     Примеры.
	     -- Все аргументы принимают значения по умолчанию
         shell.inputbox{}
	     -- Аналогично предыдущему, но со своей надписью
         shell.inputbox{prompt = "Введите число:"}
	     -- С собственными обработчиками -- ввода и результата
         shell.inputbox{
           on_enter = function(input)
             if input:match('^%s*0+%s*$') then
               shell.msgbox("0 -- не натуральное число", "Ошибка", 0x40000)
               return false
             end
             return true
           end,
           prompt = 'Введите натуральное число',
           on_char = function(char, input)
             return char:match('[%d ]')
           end}
--------------------------------------------------------------------------------
*/

extern int showinputbox(lua_State* L)
{
	if (lua_istable(L, lua_gettop(L))) {

		StackBalancer sb(L);
		LuaTable lt(L, lua_gettop(L));

		int on_char  = lt.GetFunction("on_char");
		int on_enter = lt.GetFunction("on_enter");
		int width    = lt.GetInt("width", 20);

		const char *caption = lt.GetString("caption", "InputBox");
		const char *prompt  = lt.GetString("prompt", "Enter");
		const char *value   = lt.GetString("value");

		const char *safeValue = "";
		if (!IsInputValid(L, value, on_char))
			value = safeValue;

		InputBox dlg(caption, prompt, value, width, on_char, on_enter, L);
		bool res = dlg.ShowModal() == IDOK;

		sb.Purge();

		if (res)
			lua_pushstring(L, dlg.Text());
		else
			lua_pushnil(L);
	} else {
		lua_pushnil(L);
	}
	return 1;
}

#ifdef RESTOREUNICODENESS
#  if RESTOREUNICODENESS == 3
#    define  UNICODE 1
#    define _UNICODE 1
#  elseif RESTOREUNICODENESS == 2
#    define UNICODE  1
#  else
#    define _UNICODE 1
#  endif
#  undef RESTOREUNICODENESS
#endif
