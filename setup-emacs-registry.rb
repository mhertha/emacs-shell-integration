#! ruby -w
# -*- coding: iso-8859-1 -*-

def registry_prolog
  "Windows Registry Editor Version 5.00\n"
end

def open_with_list (hive)
  %!
; Emacs Shell Addition
[#{hive}\\Software\\Classes\\*\\OpenWithList\\emacs.exe]

; Emacs Handler for Perceived Types
[#{hive}\\Software\\Classes\\SystemFileAssociations\\text\\OpenWithList\\emacs.exe]

!
end

def application (hive, emacs_root_dir)
  %!
; Emacs-Application Definition
[#{hive}\\Software\\Classes\\Applications\\emacs.exe]

[#{hive}\\Software\\Classes\\Applications\\emacs.exe\\Shell]

[#{hive}\\Software\\Classes\\Applications\\emacs.exe\\Shell\\Edit]
@="Bearbeiten mit Emacs"

[#{hive}\\Software\\Classes\\Applications\\emacs.exe\\Shell\\Edit\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacsclientw.exe\\" -na \\"#{emacs_root_dir}\\\\bin\\\\runemacs.exe\\" -c \\"%1\\""

[#{hive}\\Software\\Classes\\Applications\\emacs.exe\\Shell\\Open]

[#{hive}\\Software\\Classes\\Applications\\emacs.exe\\Shell\\Open\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacsclientw.exe\\" -na \\"#{emacs_root_dir}\\\\bin\\\\runemacs.exe\\" -c \\"%1\\""

!
end

def application_types (hive, types)
  t = %Q([#{hive}\\Software\\Classes\\Applications\\emacs.exe\\SupportedTypes]\n)
  types.sort!
  types.each { |e|
    t += %Q("#{e}"=""\n)
  }
  t
end

def text_file_types
  %w(.csv .ini .reg .rtf .txt)
end

def lang_file_types
  %w(.c .cc .cpp .cs .cxx .h)
end

def html_file_types
  %w(.css .htm .html .shtml)
end

def xml_file_types
  %w(.xml .xsl .xslt)
end

def scripting_file_types
  %w(.bas .bat .cls .cmd .frm .ps1 .vbs)
end

def progid_emacs_text (hive, emacs_root_dir)
  %!
; Emacs Text Document
[#{hive}\\Software\\Classes\\Emacs.TextDocument]
@="Emacs Textdokument"
"Content-Type"="text/plain"
"FriendlyTypeName"="Emacs Textdokument"
"InfoTip"="Bearbeite die Textdatei in einem neuen Emacs-Frame."

[#{hive}\\Software\\Classes\\Emacs.TextDocument\\DefaultIcon]
@="#{emacs_root_dir}\\\\bin\\\\emacs.exe,0"

[#{hive}\\Software\\Classes\\Emacs.TextDocument\\Shell]

[#{hive}\\Software\\Classes\\Emacs.TextDocument\\Shell\\Edit]
@="Bearbeiten mit Emacs"

[#{hive}\\Software\\Classes\\Emacs.TextDocument\\Shell\\Edit\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacsclientw.exe\\" -na \\"#{emacs_root_dir}\\\\bin\\\\runemacs.exe\\" -c \\"%1\\""

!
end

def progid_emacs_lisp_source (hive, emacs_root_dir)
  %!
; Emacs Lisp Source Code
[#{hive}\\Software\\Classes\\Emacs.LispSource]
@="Emacs Lisp Source"
"Content-Type"="text/plain"
"FriendlyTypeName"="Emacs Lisp Source"
"InfoTip"="Bearbeite die Lisp-Quelldatei in einem neuen Emacs-Frame."

[#{hive}\\Software\\Classes\\Emacs.LispSource\\DefaultIcon]
@="#{emacs_root_dir}\\\\bin\\\\emacs.exe,0"

[#{hive}\\Software\\Classes\\Emacs.LispSource\\Shell]

[#{hive}\\Software\\Classes\\Emacs.LispSource\\Shell\\Edit]
@="Bearbeiten mit Emacs"

[#{hive}\\Software\\Classes\\Emacs.LispSource\\Shell\\Edit\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacsclientw.exe\\" -na \\"#{emacs_root_dir}\\\\bin\\\\runemacs.exe\\" -c \\"%1\\""

[#{hive}\\Software\\Classes\\Emacs.LispSource\\Shell\\Compile]
@="Kompiliere mit Emacs"

[#{hive}\\Software\\Classes\\Emacs.LispSource\\Shell\\Compile\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacs.exe\\" -batch -f \\"batch-byte-compile\\" \\"%1\\""

[#{hive}\\Software\\Classes\\.el]
@="Emacs.LispSource"
"PerceivedType"="text"

!
end

def progid_emacs_lisp_bytecode (hive, emacs_root_dir)
  %!
; Emacs Lisp ByteCode
[#{hive}\\Software\\Classes\\Emacs.LispByteCode]
@="Emacs Lisp ByteCode"
"FriendlyTypeName"="Emacs Lisp ByteCode"
"InfoTip"="Führe das Programm im Batchmode mit Emacs aus."

[#{hive}\\Software\\Classes\\Emacs.LispByteCode\\DefaultIcon]
@="#{emacs_root_dir}\\\\bin\\\\emacs.exe,0"

[#{hive}\\Software\\Classes\\Emacs.LispByteCode\\Shell]

[#{hive}\\Software\\Classes\\Emacs.LispByteCode\\Shell\\Run]
@="Ausführen im Batch"

[#{hive}\\Software\\Classes\\Emacs.LispByteCode\\Shell\\Run\\Command]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacs.exe\\" -batch -l \\"%1\\""

[#{hive}\\Software\\Classes\\.elc]
@="Emacs.LispByteCode"

!
end

# http://msdn.microsoft.com/en-us/library/windows/desktop/ee872121%28v=vs.85%29.aspx
def software_app_path (hive, emacs_root_dir)
  %!
; Application Registration
[#{hive}\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\emacs.exe]
@="\\"#{emacs_root_dir}\\\\bin\\\\emacsclientw.exe\\" -c"
"Path"="#{emacs_root_dir}\\\\bin"
"HOME"=hex(2):25,00,41,00,50,00,50,00,44,00,41,00,54,00,41,00,25,00,00,00
"ALTERNATE_EDITOR"="#{emacs_root_dir}\\\\bin\\\\runemacs.exe"

!
end

emacs_folder = "C:\\\\Opt\\\\emacs-24.3"
registry_hive = "HKEY_LOCAL_MACHINE"
registry_hive = "HKEY_CURRENT_USER"

reg_file_name = "emacs-setup.reg"

reg_file = File.open(reg_file_name, "w")

reg_file.puts registry_prolog
reg_file.puts open_with_list(registry_hive)
reg_file.puts application(registry_hive, emacs_folder)
all_file_types = text_file_types + lang_file_types + html_file_types + scripting_file_types + xml_file_types
reg_file.puts application_types(registry_hive, all_file_types)

reg_file.puts progid_emacs_text(registry_hive, emacs_folder)
reg_file.puts progid_emacs_lisp_source(registry_hive, emacs_folder)
reg_file.puts progid_emacs_lisp_bytecode(registry_hive, emacs_folder)

reg_file.puts software_app_path(registry_hive, emacs_folder)

reg_file.close
