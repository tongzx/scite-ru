// twl_dialogs.cpp
#include <windows.h>
#include <commdlg.h>
#include "twl.h"
#include "twl_dialogs.h"

const int BUFFSIZE = 1024;

static char s_initial_dir[MAX_PATH];

TOpenFile::TOpenFile(TWin *parent,const char *caption, const char *filter, bool do_prompt)
{
 OPENFILENAME& ofn = *new OPENFILENAME;
 m_ofn = &ofn;
 m_prompt = do_prompt;
 m_filename = new char [BUFFSIZE];
 m_file_out = new char [MAX_PATH];
 *m_filename = '\0';
 char* p_filter = strdup(filter);
 for(char* p = p_filter; *p; p++)
     if (*p=='|') *p = '\0';

 ZeroMemory(m_ofn,sizeof(OPENFILENAME));
 ofn.lStructSize = sizeof(OPENFILENAME);
 ofn.hwndOwner = (HWND)parent->handle();
 ofn.lpstrFilter = p_filter;
 ofn.nFilterIndex = 1;
 ofn.nMaxFile = BUFFSIZE;
 ofn.lpstrTitle = (char*)caption;
 ofn.lpstrFile = m_filename;

 GetCurrentDirectory(MAX_PATH,s_initial_dir);
 initial_dir(s_initial_dir);
}

TOpenFile::~TOpenFile()
{
 delete LPOPENFILENAME(m_ofn);
 delete m_filename;
 delete m_file_out;
}

void TOpenFile::initial_dir(const char *dir)
{
 LPOPENFILENAME(m_ofn)->lpstrInitialDir = dir;
}

bool TOpenFile::go()
{
 LPOPENFILENAME ofn = LPOPENFILENAME(m_ofn);
 if (m_prompt) ofn->Flags = OFN_CREATEPROMPT | OFN_EXPLORER | OFN_ALLOWMULTISELECT;
 int ret = GetOpenFileName(ofn);
 if (ofn->nFileExtension == 0) { // multiple selection
   m_path = m_filename;
   m_file = m_filename + ofn->nFileOffset;
   ofn->nFileOffset = 0;
 } else m_path = NULL;
 return ret;
}

const char *TOpenFile::file_name()
{
 LPOPENFILENAME ofn = LPOPENFILENAME(m_ofn);
 if (m_path) { // multiple selection: build up each path individually
   strcpy(m_file_out,m_path);
   strcat(m_file_out,"\\");
   strcat(m_file_out,m_file);
   return m_file_out;
 } else
 return m_filename;
}

bool TOpenFile::next()
{
  if (m_path == NULL) return false;
  m_file += strlen(m_file)+1;
  bool finished = *m_file == '\0';
  if (finished) m_path = NULL;
  return !finished;
}

void TOpenFile::file_name(const char *file)
{
 strcpy(m_filename,file);
}

bool TSaveFile::go()
{
 if (m_prompt) LPOPENFILENAME(m_ofn)->Flags = OFN_OVERWRITEPROMPT;
 m_path = NULL;
 return GetSaveFileName((LPOPENFILENAME)m_ofn);
}

static COLORREF custom_colours[16];

TColourDialog::TColourDialog(TWin *win, unsigned int cl)
{
	LPCHOOSECOLOR clr = new CHOOSECOLOR;
	clr->lStructSize = sizeof(CHOOSECOLOR);
	clr->hwndOwner = (HWND)win->handle();
	clr->hInstance = NULL;
	clr->rgbResult = cl;
	clr->lpCustColors = custom_colours;
	clr->Flags = CC_RGBINIT | CC_FULLOPEN;
	clr->lCustData = 0;
	clr->lpfnHook = NULL;
	clr->lpTemplateName = NULL;
	m_choose_color = clr;
}


bool TColourDialog::go()
{
	return ChooseColor(LPCHOOSECOLOR(m_choose_color));
}

int TColourDialog::result()
{
	return LPCHOOSECOLOR(m_choose_color)->rgbResult;
}

