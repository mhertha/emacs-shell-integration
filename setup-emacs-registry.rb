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

def shell_command_key_edit(hive_path, emacs_icon, emacs_command)
  %!
[#{hive_path}\\Shell]

[#{hive_path}\\Shell\\Edit]
@="Bearbeiten mit Emacs"
"Icon"="#{emacs_icon}"

[#{hive_path}\\Shell\\Edit\\Command]
@="#{emacs_command} \\"%1\\""

!
end

def shell_command_key_open(hive_path, emacs_icon, emacs_command)
  %!
[#{hive_path}\\Shell]

[#{hive_path}\\Shell\\Open]
@="Öffnen mit Emacs"
"Icon"="#{emacs_icon}"

[#{hive_path}\\Shell\\Open\\Command]
@="#{emacs_command} \\"%1\\" %*"

!
end

def application (hive_root, emacs_icon, emacs_command)
  hive_path = %!#{hive_root}\\Software\\Classes\\Applications\\emacs.exe!
  %!
; Emacs-Application Definition
[#{hive_path}]

#{shell_command_key_edit(hive_path, emacs_icon, emacs_command)}
#{shell_command_key_open(hive_path, emacs_icon, emacs_command)}
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
  %w(.css .htm .html .shtml .xhtml)
end

def xml_file_types
  %w(.svg .xml .xsl .xslt)
end

def scripting_file_types
  %w(.bas .bat .cls .cmd .frm .ps1 .py .rb .vbs)
end

def progid_emacs_text (hive_root, emacs_icon, emacs_command)
  hive_path = %!#{hive_root}\\Software\\Classes\\Emacs.TextDocument!
  %!
; Emacs Text Document
[#{hive_path}]
@="Emacs Textdokument"
"Content-Type"="text/plain"
"FriendlyTypeName"="Emacs Textdokument"
"InfoTip"="Bearbeite die Textdatei in einem neuen Emacs-Frame."

[#{hive_path}\\DefaultIcon]
@="#{emacs_icon}"

#{shell_command_key_edit(hive_path, emacs_icon, emacs_command)}
#{shell_command_key_open(hive_path, emacs_icon, emacs_command)}
!
end

def progid_emacs_lisp_source (hive_root, emacs_icon, emacs_command, emacs_exe)
  hive_classes = %!#{hive_root}\\Software\\Classes!
  hive_path = %!#{hive_classes}\\Emacs.LispSource!
  %!
; Emacs Lisp Source Code
[#{hive_path}]
@="Emacs Lisp Source"
"Content-Type"="text/plain"
"FriendlyTypeName"="Emacs Lisp Source"
"InfoTip"="Bearbeite die Lisp-Quelldatei in einem neuen Emacs-Frame."

[#{hive_path}\\DefaultIcon]
@="#{emacs_icon}"

#{shell_command_key_edit(hive_path, emacs_icon, emacs_command)}
[#{hive_path}\\Shell\\Compile]
@="Kompilieren mit Emacs"
"Icon"="#{emacs_icon}"

[#{hive_path}\\Shell\\Compile\\Command]
@="\\"#{emacs_exe}\\" -batch -f \\"batch-byte-compile\\" \\"%1\\""

[#{hive_classes}\\.el]
@="Emacs.LispSource"
"PerceivedType"="text"

!
end

def progid_emacs_lisp_bytecode (hive_root, emacs_icon, emacs_exe)
  hive_classes = %!#{hive_root}\\Software\\Classes!
  hive_path = %!#{hive_classes}\\Emacs.LispByteCode!
  %!
; Emacs Lisp ByteCode
[#{hive_path}]
@="Emacs Lisp ByteCode"
"FriendlyTypeName"="Emacs Lisp ByteCode"
"InfoTip"="Führe das Programm im Batchmode mit Emacs aus."

[#{hive_path}\\DefaultIcon]
@="#{emacs_icon}"

[#{hive_path}\\Shell]

[#{hive_path}\\Shell\\Run]
@="Ausführen mit Emacs"
"Icon"="#{emacs_icon}"

[#{hive_path}\\Shell\\Run\\Command]
@="\\"#{emacs_exe}\\" -batch -l \\"%1\\""

[#{hive_classes}\\.elc]
@="Emacs.LispByteCode"

!
end

# http://msdn.microsoft.com/en-us/library/windows/desktop/ee872121%28v=vs.85%29.aspx
def software_app_path (hive, emacs_command, emacs_path)
  %!
; Application Registration
[#{hive}\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\emacs.exe]
@="#{emacs_command}"
"Path"="#{emacs_path}"

!
end

def user_environment_vars (hive_root, alternate_editor)
  %!
; Emacs-Environment Definition
[#{hive_root}\\Software\\GNU]

[#{hive_root}\\Software\\GNU\\Emacs]
"HOME"=hex(2):25,00,41,00,50,00,50,00,44,00,41,00,54,00,41,00,25,00,00,00
"ALTERNATE_EDITOR"="#{alternate_editor}"

!
end

emacs_folder = "C:\\\\Opt\\\\emacs-24.3"
machine_registry_hive = "HKEY_LOCAL_MACHINE"
user_registry_hive = "HKEY_CURRENT_USER"
registry_hive = user_registry_hive

emacs_bin = %!#{emacs_folder}\\\\bin!
emacs_exe = %!#{emacs_bin}\\\\emacs.exe!
emacs_win_exe = %!#{emacs_bin}\\\\runemacs.exe!
emacs_win_client = %!#{emacs_bin}\\\\emacsclientw.exe!
emacs_icon = %!#{emacs_exe},0!

# Command entry depends on --with-server or --standalone
emacs_command = %!\\"#{emacs_win_client}\\" -c!

reg_file_name = "emacs-setup-new.reg"

reg_file = File.open(reg_file_name, "w")

reg_file.puts registry_prolog
reg_file.puts open_with_list(registry_hive)
reg_file.puts application(registry_hive, emacs_icon, emacs_command)
all_file_types = text_file_types + lang_file_types + html_file_types + scripting_file_types + xml_file_types
reg_file.puts application_types(registry_hive, all_file_types)

reg_file.puts progid_emacs_text(registry_hive, emacs_icon, emacs_command)
reg_file.puts progid_emacs_lisp_source(registry_hive, emacs_icon, emacs_command, emacs_exe)
reg_file.puts progid_emacs_lisp_bytecode(registry_hive, emacs_icon, emacs_exe)

reg_file.puts software_app_path(registry_hive, emacs_command, emacs_bin)
reg_file.puts user_environment_vars(user_registry_hive, emacs_win_exe)

reg_file.close
