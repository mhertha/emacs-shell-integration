#! ruby -w
# -*- coding: iso-8859-1 -*-
#
# setup-emacs-registry.rb
# Create windows registry definitions to integrate GNU emacs within
# the windows environment.
#
# Copyright (C) 2014 Maik Hertha (mhertha@gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'optparse'

def registry_prolog
  %!Windows Registry Editor Version 5.00\n\n!
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
  def print_registry_create(reg_path)
    s = verb_description(reg_path)
    s += verb_command(reg_path)
    s
  end
  def print_registry_remove(reg_path)
    %![-#{reg_path}\\#{@verb}]\n\n!
  end
end

class SoftwareClassesKey
  SOFTWARE_CLASSES_KEY = %!Software\\Classes!
  
  def initialize(registry_hive, classes_subkey)
    @hive_path = %!#{registry_hive}\\#{SOFTWARE_CLASSES_KEY}!
    @hive_path += %!\\#{classes_subkey}! if classes_subkey
    @verbs = Array.new
  end

  def key_path
    %!#{@hive_path}!
  end
  def print_registry_subkey(sub_key, option_char)
    %![#{option_char}#{key_path}\\#{sub_key}]\n\n!
  end
  def print_create_subkey(sub_key)
    print_registry_subkey(sub_key, "")
  end
  def print_remove_subkey(sub_key)
    print_registry_subkey(sub_key, "-")
  end

  def add_verb(new_verb)
    @verbs.push(new_verb)
  end
  def print_shell_verbs_create
    t = ""
    @verbs.each{ |v|
      t += v.print_registry_create(key_path)
    }
    t
  end
  def print_shell_verbs_remove
    t = ""
    @verbs.each{ |v|
      t += v.print_registry_remove(key_path)
    }
    t
  end
end

class SoftwareClassesApplicationsKey < SoftwareClassesKey

  def initialize(registry_hive, application_name)
    super(registry_hive, "Applications\\#{application_name}")
  end

  def print_create_key
    %![#{key_path}]\n\n!
  end

  def print_registry_create
    t = print_create_key
    t += print_shell_verbs_create
    t
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
    super(registry_hive, file_extension)
    @progid_name = progid_name
    @content_type = nil
    @perceived_type = nil
  end

  def print_registry_create
    t = %![#{key_path}]\n!
    t += %!@="#{@progid_name}"\n! if @progid_name
    t += %!"Content Type"="#{content_type}"\n! if @content_type
    t += %!"PerceivedType"="#{perceived_type}"\n! if @perceived_type
    t += %!\n!
    t
  end
  def print_registry_delete
    %![-#{key_path}]\n\n!
  end

  # Add or remove a foreign progid to this file extension
  def print_progid_option(progid_addition, option_char)
    %![#{key_path}\\OpenWithProgIds]
"#{progid_addition}"=#{option_char}

!
  end
  def print_add_progid(progid_name)
    print_progid_option(progid_name, "\"\"")
  end
  def print_remove_progid(progid_name)
    print_progid_option(progid_name, "-")
  end
end

class SoftwareClassesProgIdKey < SoftwareClassesKey

  attr_accessor :default_icon, :info_tip
  attr_reader :progid_name

  def initialize(registry_hive, progid_name, friendly_type_name)
    super(registry_hive, progid_name)
    @progid_name = progid_name
    @friendly_type_name = friendly_type_name
    @default_icon = nil
    @info_tip = nil
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
        t += v.print_registry_create(shell_path)
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

def reg_sz_or_expand_value(reg_value)
  # REG_SZ string has to be quoted in the registry file
  return_value = "\"#{reg_value}\""
  # if there is any environment variable, the whole value has to be encoded
  if (reg_value =~ /%[A-Za-z_]+%/)
    elts = []
    # Each char is null terminated by default
    reg_value.each_byte { |b| elts << b.to_s(16) << "00" }
    # REG_EXPAND_SZ is a null terminated string
    elts << "00" << "00"
    return_value = "hex(2):#{elts.join(',')}"
  end
  return_value
end

class SoftwareEnvironmentKey

  def initialize(registry_hive)
    @hive_path = %!#{registry_hive}\\Software\\GNU!
  end

  def print_registry_create(home_dir, alternate_editor)
    home_reg_var = reg_sz_or_expand_value(home_dir)
    editor_reg_var = reg_sz_or_expand_value(alternate_editor)

    %![#{@hive_path}]

[#{@hive_path}\\Emacs]
"HOME"=#{home_reg_var}
"ALTERNATE_EDITOR"=#{editor_reg_var}

!
  end
  def print_registry_delete
    %![-#{@hive_path}\\Emacs]\n\n!
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

def write_registry_files(work_opts, emacs_app)

  registry_hive = work_opts[:registry_hive]

  create_file = File.open(work_opts[:setup_file], "w")
  cleanup_file = File.open(work_opts[:cleanup_file], "w")

  create_file.puts registry_prolog
  cleanup_file.puts registry_prolog

  # Shell verbs used for multiple key definitions
  emacs_app_command = emacs_app.command(work_opts[:server_mode], work_opts[:new_frame])
  emacs_edit_command = %!#{emacs_app_command} \\"%1\\" %*!
  edit_verb = ShellVerb.new(
                "Edit",
                "Bearbeiten mit Emacs",
                emacs_edit_command,
                emacs_app.icon)
  emacs_open_command = %!#{emacs_app_command} \\"%1\\"!
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
                     emacs_app_command,
                     emacs_app.bin_path)
  cleanup_file.puts application.print_registry_delete

  # The environment settings for each emacs instance
  environment = SoftwareEnvironmentKey.new(registry_hive)
  create_file.puts environment.print_registry_create(work_opts[:home_dir], work_opts[:alternate_editor])
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
  # http://msdn.microsoft.com/en-us/library/windows/desktop/cc144067%28v=vs.85%29.aspx
  # Directory are File folders, Folder are All folders
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
  generic_handler = SoftwareClassesKey.new(registry_hive, "*")
  create_file.puts %!; Emacs Shell Addition!
  create_file.puts generic_handler.print_create_subkey(open_with_emacs)
  cleanup_file.puts %!; Remove Emacs Shell Addition!
  cleanup_file.puts generic_handler.print_remove_subkey(open_with_emacs)

  perceived_text_handler = SoftwareClassesKey.new(
                              registry_hive,
                              "SystemFileAssociations\\text")
  perceived_text_handler.add_verb(edit_verb)
  perceived_text_handler.add_verb(open_verb)
  create_file.puts %!; Emacs Handler for Perceived Types!
  create_file.puts perceived_text_handler.print_create_subkey(open_with_emacs)
  create_file.puts perceived_text_handler.print_shell_verbs_create
  cleanup_file.puts %!; Remove Emacs Handler for Perceived Types!
  cleanup_file.puts perceived_text_handler.print_remove_subkey(open_with_emacs)
  cleanup_file.puts perceived_text_handler.print_shell_verbs_remove

  create_file.close
  cleanup_file.close
end

local_machine_registry = "HKEY_LOCAL_MACHINE"
current_user_registry = "HKEY_CURRENT_USER"
default_setup_file = 'emacs-setup-create.reg'
default_cleanup_file = 'emacs-setup-cleanup.reg'
default_home_dir = '%APPDATA%'
default_editor = 'runemacs.exe'

options = {
  :emacs_directory => 'C:\\\\Opt\\\\emacs-24.3',
  :registry_hive => current_user_registry,
  :server_mode => true,
  :new_frame => true,
  :setup_file => default_setup_file,
  :cleanup_file => default_cleanup_file,
  :home_dir => default_home_dir,
  :alternate_editor => default_editor,
}

opt_parser = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help') do
    puts <<-EOL
setup-emacs-registry.rb
Copyright (C) 2014 Maik Hertha (mhertha@gmail.com)
    
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.

EOL
    puts opts
    exit
  end
  opts.on('-d',
          '--emacs-directory DIRECTORY',
          'Root Directory for emacs.exe') do |dir|
    # todo: escape path separator!
    options[:emacs_directory] = dir
  end
  opts.on('--registry-hklm',
          "Create the keys under #{local_machine_registry} (Default: #{current_user_registry})") do
    options[:registry_hive] = local_machine_registry
  end
  opts.on('-S',
          '--standalone',
          'Define runemacs.exe as default editor otherwise emacsclientw.exe is used.') do
    options[:server_mode] = false
  end
  opts.on('-F',
          '--single-frame',
          'Open each file in the running emacs-frame (if emacs has server-mode active).') do
    options[:new_frame] = false
  end
  opts.on('--setup-file SETUPFILE',
          "Write registry keys for install settings to SETUPFILE (Default: #{default_setup_file})") do |f|
    options[:setup_file] = f
  end
  opts.on('--cleanup-file CLEANUPFILE',
          "Write registry keys for remove settings to CLEANUPFILE (Default: #{default_cleanup_file})") do |f|
    options[:cleanup_file] = f
  end
  opts.on('--home-dir HOMEVAR',
          "Use HOMEVAR as environment variable for emacs (Default: #{default_home_dir})") do |h|
    options[:home_dir] = h
  end
  opts.on('-E',
          '--alternate-editor EDITOR',
          "Use EDITOR as alternate editor for emacs in server-mode (Default: #{default_editor})") do |e|
    options[:alternate_editor] = e
  end
end

opt_parser.parse!

# Default GNU emacs application found at
# http://ftp.gnu.org/gnu/emacs/windows/
emacs_app = EmacsApplication.new(options[:emacs_directory])

if (! File::exists?(emacs_app.win_exe))

  puts "Emacs binary '#{emacs_app.win_exe}' not found!"
  puts 'Abort!'
  exit 1

end

# The default setting is a placeholder. At this position
# the full path is available.
if (options[:alternate_editor].eql?(default_editor))
  options[:alternate_editor] = emacs_app.win_exe
end

write_registry_files(options, emacs_app)
