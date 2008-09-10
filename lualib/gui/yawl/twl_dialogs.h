// twl_dialogs.h

#ifndef __TWL_DIALOGS_H
#define __TWL_DIALOGS_H

class EXPORT TOpenFile {
protected:
  void *m_ofn;
  char *m_filename;
  bool m_prompt;
  char *m_file;
  char *m_file_out;
  char *m_path;
public:
  TOpenFile(TWin *parent,const char *caption,const char *filter,bool do_prompt=true);
  ~TOpenFile();
  virtual bool go();
  void initial_dir(const char *dir);
  bool next();
  const char *file_name();
  void file_name(const char *buff);
};

class EXPORT TSaveFile: public TOpenFile {
  public:
  TSaveFile(TWin *parent, const char *caption, const char *filter,bool do_prompt=true)
   : TOpenFile(parent,caption,filter,false)
   {}
   bool go();
};

class EXPORT TColourDialog {
protected:
	void *m_choose_color;
public:
	TColourDialog(TWin *parent, unsigned int clr);
	virtual bool go();
	int result();
};
#endif
