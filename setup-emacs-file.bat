@echo off
rem Setup the file association
rem See: http://www.emacswiki.org/emacs/EmacsMsWindowsIntegration
rem 2013.09.23 Maik - Initial Version.
rem
ftype txtfile=c:\opt\emacs-24.3\bin\emacsclientw.exe -na "c:\opt\emacs-24.3\bin\runemacs.exe" "%1"
ftype EmacsLisp=c:\opt\emacs-24.3\bin\emacsclientw.exe -na "c:\opt\emacs-24.3\bin\runemacs.exe" "%1"
ftype CodeFile=c:\opt\emacs-24.3\bin\emacsclientw.exe -na "c:\opt\emacs-24.3\bin\runemacs.exe" "%1"
assoc .txt=txtfile
assoc .text=txtfile
assoc .log=txtfile
assoc .el=EmacsLisp
assoc .c=CodeFile
assoc .h=CodeFile