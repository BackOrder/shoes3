#
# Build shoes for Windows/Gtk3  Ruby is cross compiled
# It's not really a chroot - it only looks like one
# Remember, on Windows the dlls are in bin/ 
cf =(ENV['ENV_CUSTOM'] || "#{TGT_ARCH}-custom.yaml")
if File.exists? cf
  custmz = YAML.load_file(cf)
  ShoesDeps = custmz['Deps']
  EXT_RUBY = custmz['Ruby']
  ENABLE_MS_THEME = custmz['MS-Theme'] == true
  ENV['GDB'] = 'basic' if custmz['Debug'] == true
  APP['GEMLOC'] = custmz['Gemloc'] if custmz['Gemloc']
  APP['EXTLOC'] = custmz['Extloc'] if custmz['Extloc']
  APP['EXTLIST'] = custmz['Exts'] if custmz['Exts']
  APP['GEMLIST'] = custmz['Gems'] if custmz['Gems']
  APP['INCLGEMS'] = custmz['InclGems'] if custmz['InclGems']
  #gtk_version = custmz['GtkVersion'].to_s if custmz['GtkVersion']
  #APP['VIDEO'] = true
else
  # define where your deps are
  ShoesDeps = "/home/ccoupe/Projects/shoesdeps/mingw"
  EXT_RUBY = "#{ShoesDeps}/usr/local"
  ENABLE_MS_THEME = false
end
APP['GTK'] == "gtk+-3.0" # needed in tasks.rb
#SHOES_GEM_ARCH = {Gem::Platform.local}
SHOES_GEM_ARCH = 'x86-mingw32' 

#ENV['DEBUG'] = "true" # turns on the tracing log
#ENV['GDB'] = "basic" # 'basic' = keep symbols,  or 'profile'
SHOES_TGT_ARCH = "i386-mingw32"
# Specify where the Target system binaries live. 
# Trailing slash is important.
TGT_SYS_DIR = "#{ShoesDeps}/"
# Setup some shortcuts for the library locations. These are not ruby paths. 
# depends on what ruby was compiled to produce. Don't guess. 
arch = 'i386-mingw32'
uldir = "#{TGT_SYS_DIR}lib"
ularch = "#{TGT_SYS_DIR}lib"
larch = "#{TGT_SYS_DIR}lib/"
bindll = "#{TGT_SYS_DIR}bin"
ulbin = "#{TGT_SYS_DIR}usr/local/bin"
# Set appropriately (in my PATH, or use abs)
CC = "i686-w64-mingw32-gcc"
STRIP = "strip -x"
WINDRES = "i686-w64-mingw32-windres"
# These ENV vars are used by the extconf.rb files
ENV['SYSROOT']=ShoesDeps
ENV['CC']=CC
ENV['TGT_RUBY_PATH']=EXT_RUBY
ENV['TGT_ARCH'] = SHOES_TGT_ARCH
ENV['TGT_RUBY_V'] = '2.2.0'
TGT_RUBY_V = ENV['TGT_RUBY_V'] 
ENV['TGT_RUBY_SO'] = "msvcrt-ruby220"
EXT_RBCONFIG = "#{EXT_RUBY}/lib/ruby/#{TGT_RUBY_V}/#{SHOES_TGT_ARCH}/rbconfig.rb"
ENV['EXT_RBCONFIG'] = EXT_RBCONFIG 

pkgruby ="#{EXT_RUBY}/lib/pkgconfig/ruby-2.2.pc"
pkggtk ="#{uldir}/pkgconfig/gtk+-3.0.pc" 
# winhttp or RUBY?
RUBY_HTTP = true

ENV['PKG_CONFIG_PATH'] = "#{ularch}/pkgconfig"
WINVERSION = "#{APP['VERSION']}-gtk3-32"
WINFNAME = "#{APPNAME}-#{WINVERSION}"

gtk_extra_list = %w(shoes/native/gtkfixedalt.c shoes/native/gtkentryalt.c
               shoes/native/gtkcomboboxtextalt.c shoes/native/gtkbuttonalt.c
               shoes/native/gtkscrolledwindowalt.c shoes/native/gtkprogressbaralt.c)
file_list = %w{shoes/native/gtk.c shoes/http/rbload.c} + gtk_extra_list + ["shoes/*.c"]
file_list << "shoes/video/video.c" 
file_list << "shoes/console/gtk-terminal.c"
SRC = FileList[*file_list]
OBJ = SRC.map do |x|
  x.gsub(/\.\w+$/, '.o')
end

ADD_DLL = []

# Hand code for your situation 
def xfixip(path)
   path.gsub!(/-I\/usr\//, "-I#{TGT_SYS_DIR}usr/")
   return path
end

def xfixrvmp(path)
  path.gsub!(/-I\/usr\/local\//, "-I/#{TGT_SYS_DIR}usr/local/")
  return path
end


# Target environment
CAIRO_CFLAGS = `pkg-config --cflags "#{ularch}/pkgconfig/cairo.pc"`.strip
CAIRO_LIB = `pkg-config --libs "#{ularch}/pkgconfig/cairo.pc"`.strip
PANGO_CFLAGS = `pkg-config --cflags "#{ularch}/pkgconfig/pango.pc"`.strip
PANGO_LIB = `pkg-config --libs "#{ularch}/pkgconfig/pango.pc"`.strip

png_lib = 'png'

if ENV['DEBUG'] || ENV['GDB']
  LINUX_CFLAGS = " -g3 -O0"
else
  LINUX_CFLAGS = " -O -Wall"
end

LINUX_CFLAGS << " -DSHOES_GTK -DSHOES_GTK_WIN32 "
LINUX_CFLAGS << "-DRUBY_HTTP "
LINUX_CFLAGS << xfixrvmp(`pkg-config --cflags "#{pkgruby}"`.strip)+" "
LINUX_CFLAGS << " -I#{TGT_SYS_DIR}usr/include/#{arch} "
LINUX_CFLAGS << xfixip("-I/usr/include")+" "
LINUX_CFLAGS << xfixip(`pkg-config --cflags "#{pkggtk}"`.strip)+" "
LINUX_CFLAGS << "-I#{ShoesDeps}/include/librsvg-2.0/librsvg "
LINUX_CFLAGS << " -I#{TGT_SYS_DIR}usr/local/include "
if ENV['GDB']== 'profile'
  LINUX_CFLAGS <<  '-pg'
end
LINUX_CFLAGS << " -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unused-function"
LINUX_CFLAGS << " -mms-bitfields -D__MINGW_USE_VC2005_COMPAT -DXMD_H -D_WIN32_IE=0x0500 -D_WIN32_WINNT=0x0501 -DWINVER=0x0501 -DCOBJMACROS "

# I don't think the line below belongs in this file. 
# It should probably be in tasks/prebuild or tasks/package
cp APP['icons']['win32'], "shoes/appwin32.ico"

LINUX_LIB_NAMES = %W[gif-4 jpeg librsvg-2 libffi]

DLEXT = "dll"
LINUX_LDFLAGS = "-shared -L#{ularch} "
LINUX_LDFLAGS << `pkg-config --libs "#{pkggtk}"`.strip+" "

# dont use the ruby link info
RUBY_LDFLAGS = "-Wl,-export-all-symbols "
RUBY_LDFLAGS << "-L#{EXT_RUBY}/lib -lmsvcrt-ruby220 "

LINUX_LDFLAGS << "#{ENV['GDB'] == 'profile' ? '-pg' : ' '} -lwinhttp -lshell32 -lkernel32 -luser32 -lgdi32 -lcomdlg32 -lcomctl32 "

LINUX_LIBS = " -L#{bindll} "
LINUX_LIBS << LINUX_LIB_NAMES.map { |x| "-l#{x}" }.join(' ')

LINUX_LIBS << " #{RUBY_LDFLAGS} #{CAIRO_LIB} #{PANGO_LIB} "

# This should be used in pre_build instead of copy_deps_to_dist, 
# although either could work. 
# Reference: http://www.gtk.org/download/win32_contentlist.php
SOLOCS = {
  'ruby'    => "#{EXT_RUBY}/bin/msvcrt-ruby220.dll",
  #'ungif'  => "#{uldir}/libungif.so.4",
  'gif'     => "#{bindll}/libgif-4.dll",
  'jpeg'    => "#{bindll}/libjpeg-9.dll",
  'libyaml' => "#{bindll}/libyaml-0-2.dll",
  #'intl'    => "#{bindll}/intl.dll",
  'iconv'   => "#{bindll}/libiconv-2.dll",
  #'ffi'     => "#{bindll}/libffi-5.dll",
  'eay'     => "#{bindll}/libeay32.dll",
  #'gdbm'    => "#{bindll}/libgdbm-3.dll",
  #'gdbmc'   => "#{bindll}/libgdbm_compat-3.dll",
  'gdbm'    => "#{bindll}/libgdbm-4.dll",
  'ssl'     => "#{bindll}/ssleay32.dll",
  'sqlite'  => "#{bindll}/sqlite3.dll"
}

SOLOCS.merge!(
    {
      'atk'         => "#{bindll}/libatk-1.0-0.dll",
      'cairo'       => "#{bindll}/libcairo-2.dll",
      'cairo-gobj'  => "#{bindll}/libcairo-gobject-2.dll",
      'ffi'         => "#{bindll}/libffi-6.dll",
      'fontconfig'  => "#{bindll}/libfontconfig-1.dll",
      'freetype'    => "#{bindll}/libfreetype-6.dll",
      'gdkpixbuf'   => "#{bindll}/libgdk_pixbuf-2.0-0.dll",
      'gdk3'        => "#{bindll}/libgdk-3-0.dll",
      'gio'         => "#{bindll}/libgio-2.0-0.dll",
      'glib'        => "#{bindll}/libglib-2.0-0.dll",
      'gmodule'     => "#{bindll}/libgmodule-2.0-0.dll",
      'gobject'     => "#{bindll}/libgobject-2.0-0.dll",
      'gtk3'        => "#{bindll}/libgtk-3-0.dll",
      'pixman'      => "#{bindll}/libpixman-1-0.dll", 
      'intl8'        => "#{bindll}/libintl-8.dll",
      'pango'       => "#{bindll}/libpango-1.0-0.dll",
      'pangocairo'  => "#{bindll}/libpangocairo-1.0-0.dll",
      'pangoft'     => "#{bindll}/libpangoft2-1.0-0.dll",
      'pango32'     => "#{bindll}/libpangowin32-1.0-0.dll",
      'pixbuf'      => "#{bindll}/libgdk_pixbuf-2.0-0.dll",
      'harfbuzz'    => "#{bindll}/libharfbuzz-0.dll",
      'png16'       => "#{bindll}/libpng16-16.dll",
      'xml2'        => "#{bindll}/libxml2-2.dll",
      'croco'       => "#{bindll}/libcroco-0.6-3.dll",
      'rsvg'        => "#{bindll}/librsvg-2-2.dll",
      'thread'      => "#{bindll}/libgthread-2.0-0.dll",
      'zlib1'       => "#{bindll}/zlib1.dll",
      'siji'        => "/usr/lib/gcc/i686-w64-mingw32/4.8/libgcc_s_sjlj-1.dll",
      'pthread'     => "/usr/i686-w64-mingw32/lib/libwinpthread-1.dll" 
    }
  )

