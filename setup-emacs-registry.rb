#! ruby -w
# -*- coding: iso-8859-1 -*-

def registry_prolog
  "Windows Registry Editor Version 5.00\n"
end

class ShellVerb
  def initialize(verb, description, command, icon)
    @verb = verb
    @description = description
    @command = command
    @icon = icon
  end

  def verb_description(reg_path)
    v = %![#{reg_path}\\#{@verb}]\n!
    v += %!@="#{@description}"\n! if @description
    v += %!"Icon"="#{@icon}"\n! if @icon
    v += %!\n!
    v
  end
  def verb_command(reg_path)
    v = %![#{reg_path}\\#{@verb}\\Command]\n!
    v += %!@="#{@command}"\n!
    v += %!\n!
    v
  end
  def print_registry_value(reg_path)
    s = verb_description(reg_path)
    s += verb_command(reg_path)
    s
  end
  def print_registry_remove(reg_path)
    %![-#{reg_path}\\#{@verb}]\n\n!
  end
end

class SoftwareClassesKey
  REG_KEYPATH = %!Software\\Classes!
  
  def initialize(registry_hive)
    @hive_path = %!#{registry_hive}\\#{REG_KEYPATH}!
    @verbs = Array.new
  end

  def key_path
    %!#{@hive_path}!
  end
  def print_registry_key(sub_key, option_char)
    %![#{option_char}#{key_path}\\#{sub_key}]\n\n!
  end
  def print_add_key(sub_key)
    print_registry_key(sub_key, "")
  end
  def print_remove_key(sub_key)
    print_registry_key(sub_key, "-")
  end

  def add_verb(new_verb)
    @verbs.push(new_verb)
  end
  def print_shell_verbs
    t = ""
    @verbs.each{ |v|
      t += v.print_registry_value(key_path)
    }
    t
  end
end

class SoftwareClassesApplicationsKey < SoftwareClassesKey

  def initialize(registry_hive, application_name)
    super(registry_hive)
    @application_name = application_name
  end

  def key_path
    %!#{@hive_path}\\Applications\\#{@application_name}!
  end

  def print_registry_create
    t = print_add_key
    t += print_shell_verbs
    t
  end

  def print_add_key
    %![#{key_path}]\n\n!
  end
  def print_registry_delete
    %![-#{key_path}]\n\n!
  end

  def print_supported_types(types)
    t = %Q([#{key_path}\\SupportedTypes]\n)
    types.sort!
    types.each { |e|
      t += %Q("#{e}"=""\n)
    }
    t += %!\n!
    t
  end
end

class SoftwareClassesExtensionKey < SoftwareClassesKey

  attr_accessor :perceived_type, :content_type

  def initialize(registry_hive, file_extension, progid_name)
    super(registry_hive)
    @file_extension = file_extension
    @progid_name = progid_name
    @content_type = nil
    @perceived_type = nil
  end
  def key_path
    %!#{@hive_path}\\#{@file_extension}!
  end
  def print_registry_create
    t = %![#{key_path}]\n!
    t += %!@="#{@progid_name}"\n! if @progid_name
    t += %!"Content Type"="#{content_type}"\n! if @content_type
    t += %!"PerceivedType"="#{@perceived_type}"\n! if @perceived_type
    t += %!\n!
    t
  end
  def print_registry_delete
    %![-#{key_path}]\n\n!
  end

  # Add or remove a foreign progid to this file extension
  def print_open_with_progid(progid_addition, option_char)
    %![#{key_path}\\OpenWithProgids]
"#{progid_addition}"=#{option_char}

!
  end
  def print_add_progid(progid_name)
    print_open_with_progid(progid_name, "\"\"")
  end
  def print_remove_progid(progid_name)
    print_open_with_progid(progid_name, "-")
  end
end

class SoftwareClassesProgIdKey < SoftwareClassesKey

  attr_accessor :default_icon, :info_tip
  attr_reader :progid_name

  def initialize(registry_hive, progid_name, friendly_type_name)
    super(registry_hive)
    @progid_name = progid_name
    @friendly_type_name = friendly_type_name
    @default_icon = nil
    @info_tip = nil
  end

  def key_path
    %!#{@hive_path}\\#{@progid_name}!
  end
  def progid_registry_create
    t = %![#{key_path}]\n!
    if (@friendly_type_name)
      t += %!@="#{@friendly_type_name}"\n!
      t += %!"FriendlyTypeName"="#{@friendly_type_name}"\n!
    end
    t += %!"InfoTip"="#{@info_tip}"\n! if @info_tip
    t += %!\n!
    t
  end
  def subkey_icon
    %![#{key_path}\\DefaultIcon]
@="#{@default_icon}"

!
  end
  def print_add_verbs
    shell_path = %!#{key_path}\\Shell!
    t = ""
    if (@verbs)
      t = %![#{shell_path}]\n\n!
      @verbs.each { |v|
        t += v.print_registry_value(shell_path)
      }
    end
    t
  end
  def print_remove_verbs
    shell_path = %!#{key_path}\\Shell!
    t = ""
    if (@verbs)
      @verbs.each { |v|
        t += v.print_registry_remove(shell_path)
      }
    end
    t
  end
  def print_registry_create
    t = progid_registry_create
    t += subkey_icon if @default_icon
    t += print_add_verbs if @verbs.size > 0
    t
  end
  def print_registry_delete
    %![-#{key_path}]\n\n!
  end

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

# http://msdn.microsoft.com/en-us/library/windows/desktop/ee872121%28v=vs.85%29.aspx
class ApplicationKey
  REG_KEYPATH = %!Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\emacs.exe!
  def initialize(registry_hive)
    @hive_path = %!#{registry_hive}\\#{REG_KEYPATH}!
  end

  def print_registry_create(emacs_command, emacs_path)
    %!; Application Registration
[#{@hive_path}]
@="#{emacs_command}"
"Path"="#{emacs_path}"

!
  end
  def print_registry_delete
    %!; Remove Application Registration
[-#{@hive_path}]

!
  end
end

class EnvironmentKey
  REG_KEYPATH = %!Software\\GNU!
  def initialize(registry_hive)
    @hive_path = %!#{registry_hive}\\#{REG_KEYPATH}!
  end

  def print_registry_create(alternate_editor)
    %!; Emacs-Environment Definition
[#{@hive_path}]

[#{@hive_path}\\Emacs]
"HOME"=hex(2):25,00,41,00,50,00,50,00,44,00,41,00,54,00,41,00,25,00,00,00
"ALTERNATE_EDITOR"="#{alternate_editor}"

!
  end
  def print_registry_delete
    %!; Remove Environment Registration
[-#{@hive_path}\\Emacs]

!
  end
end

class EmacsApplication
  def initialize(emacs_path)
    @root_path = emacs_path
  end

  def bin_path
    %!#{@root_path}\\\\bin!
  end
  def main_app
    %!emacs.exe!
  end
  def console_exe
    %!#{bin_path}\\\\#{main_app}!
  end
  def console_client
    %!#{bin_path}\\\\emacsclient.exe!
  end
  def win_exe
    %!#{bin_path}\\\\runemacs.exe!
  end
  def win_client
    %!#{bin_path}\\\\emacsclientw.exe!
  end
  def icon
    %!#{console_exe},0!
  end
  def application_path(with_server)
    with_server ? win_client : win_exe
  end
  def command(with_server, new_frame)
    # Command entry depends on --with-server or --standalone emacs_command
    # A new emacs frame is only possible with server mode.
    %!\\"#{application_path(with_server)}\\"#{with_server && new_frame ? " -c" : ""}!
  end
end

def write_registry_files(registry_hive, emacs_app)

  file_name_create = "emacs-setup-create.reg"
  file_name_cleanup = "emacs-setup-cleanup.reg"

  create_file = File.open(file_name_create, "w")
  cleanup_file = File.open(file_name_cleanup, "w")

  create_file.puts registry_prolog
  cleanup_file.puts registry_prolog

  # Shell verbs used for multiple key definitions
  emacs_edit_command = %!#{emacs_app.command(true,true)} \\"%1\\" %*!
  edit_verb = ShellVerb.new(
                "Edit",
                "Bearbeiten mit Emacs",
                emacs_edit_command,
                emacs_app.icon)
  emacs_open_command = %!#{emacs_app.command(true,true)} \\"%1\\"!
  open_verb = ShellVerb.new(
                "Open",
                "Öffnen mit Emacs",
                emacs_open_command,
                emacs_app.icon)
  emacs_compile_command = %!\\"#{emacs_app.console_exe}\\" -batch -f \\"batch-byte-compile\\" \\"%1\\"!
  compile_verb = ShellVerb.new(
                "Compile",
                "Kompilieren mit Emacs",
                emacs_compile_command,
                emacs_app.icon)
  emacs_run_command = %!\\"#{emacs_app.console_exe}\\" -batch -l \\"%1\\"!
  run_verb = ShellVerb.new(
                "Run",
                "Ausführen mit Emacs",
                emacs_run_command,
                emacs_app.icon)

  # Add the application definition for the windows shell
  # will be used for OpenWithList definition
  application = ApplicationKey.new(registry_hive)
  create_file.puts application.print_registry_create(
                     emacs_app.command(true, true),
                     emacs_app.bin_path)
  cleanup_file.puts application.print_registry_delete

  # The environment settings for each emacs instance
  environment = EnvironmentKey.new(registry_hive)
  create_file.puts environment.print_registry_create(emacs_app.win_exe)
  cleanup_file.puts environment.print_registry_delete

  # Definition for file types used with emacs
  # See: http://msdn.microsoft.com/en-us/library/windows/desktop/cc144148%28v=vs.85%29.aspx
  all_file_types = text_file_types + lang_file_types + html_file_types + scripting_file_types + xml_file_types
  emacs_classes = SoftwareClassesApplicationsKey.new(
                          registry_hive,
                          emacs_app.main_app)
  emacs_classes.add_verb(open_verb)
  emacs_classes.add_verb(edit_verb)
  create_file.puts emacs_classes.print_registry_create
  create_file.puts emacs_classes.print_supported_types(all_file_types)
  cleanup_file.puts emacs_classes.print_registry_delete

  progid_emacs_text = SoftwareClassesProgIdKey.new(
                          registry_hive,
                          "Emacs.TextFile",
                          "Emacs Textdokument")
  progid_emacs_text.default_icon = emacs_app.icon
  progid_emacs_text.info_tip = "Bearbeite die Textdatei in einem neuen Emacs-Frame."
  progid_emacs_text.add_verb(edit_verb)
  progid_emacs_text.add_verb(open_verb)
  create_file.puts progid_emacs_text.print_registry_create
  cleanup_file.puts progid_emacs_text.print_registry_delete

  progid_emacs_lisp = SoftwareClassesProgIdKey.new(
                          registry_hive,
                          "Emacs.LispSource",
                          "Emacs Lisp Quelltext")
  progid_emacs_lisp.default_icon = emacs_app.icon
  progid_emacs_lisp.info_tip = "Bearbeite die Lisp-Quelldatei in einem neuen Emacs-Frame."
  progid_emacs_lisp.add_verb(edit_verb)
  progid_emacs_lisp.add_verb(compile_verb)
  create_file.puts progid_emacs_lisp.print_registry_create
  cleanup_file.puts progid_emacs_lisp.print_registry_delete

  progid_emacs_byte = SoftwareClassesProgIdKey.new(
                          registry_hive,
                          "Emacs.LispByteCode",
                          "Emacs Lisp ByteCode")
  progid_emacs_byte.default_icon = emacs_app.icon
  progid_emacs_byte.info_tip = "Führe das Programm im Batchmode mit Emacs aus."
  progid_emacs_byte.add_verb(run_verb)
  create_file.puts progid_emacs_byte.print_registry_create
  cleanup_file.puts progid_emacs_byte.print_registry_delete

  file_extension_el = SoftwareClassesExtensionKey.new(
                          registry_hive,
                          ".el", 
                          progid_emacs_lisp.progid_name)
  file_extension_el.content_type = "text/plain"
  create_file.puts file_extension_el.print_registry_create
  cleanup_file.puts file_extension_el.print_registry_delete

  file_extension_elc = SoftwareClassesExtensionKey.new(
                          registry_hive,
                          ".elc", 
                          progid_emacs_byte.progid_name)
  create_file.puts file_extension_elc.print_registry_create
  cleanup_file.puts file_extension_elc.print_registry_delete

  # Add Support for emacs to all file extensions
  all_file_types.each { |t|
    ext = SoftwareClassesExtensionKey.new(registry_hive, t, nil)
    create_file.puts ext.print_add_progid(progid_emacs_text.progid_name)
    cleanup_file.puts ext.print_remove_progid(progid_emacs_text.progid_name)
  }

  # Add support for emacs dired mode
  ["Directory", "Folder"].each { |t|
    progid_emacs_folder = SoftwareClassesProgIdKey.new(
                          registry_hive,
                          t,
                          nil)
    progid_emacs_folder.add_verb(edit_verb)
    create_file.puts progid_emacs_folder.print_registry_create
    cleanup_file.puts progid_emacs_folder.print_remove_verbs
  }

  open_with_emacs = %!OpenWithList\\emacs.exe!
  generic_handler = SoftwareClassesKey.new(registry_hive)
  create_file.puts %!; Emacs Shell Addition!
  create_file.puts generic_handler.print_add_key(%!*\\#{open_with_emacs}!)
  cleanup_file.puts generic_handler.print_remove_key(%!*\\#{open_with_emacs}!)
  create_file.puts %!; Emacs Handler for Perceived Types!
  create_file.puts generic_handler.print_add_key(%!SystemFileAssociations\\text\\#{open_with_emacs}!)
  cleanup_file.puts generic_handler.print_remove_key(%!SystemFileAssociations\\text\\#{open_with_emacs}!)

  create_file.close
  cleanup_file.close
end

emacs_folder = "C:\\\\Opt\\\\emacs-24.3"
machine_registry_hive = "HKEY_LOCAL_MACHINE"
user_registry_hive = "HKEY_CURRENT_USER"
registry_hive = user_registry_hive

# Default GNU emacs application found at
# http://ftp.gnu.org/
emacs_app = EmacsApplication.new(emacs_folder)

write_registry_files(registry_hive, emacs_app)
