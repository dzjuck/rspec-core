class OutputWrapper
  attr_accessor :output

  def initialize(output)
    @output = output
  end

  [:<<, :advise, :autoclose=, :autoclose?, :binmode, :binmode?, :bytes, :chars, :close, :close_on_exec=,
   :close_on_exec?, :close_read, :close_write, :closed?, :codepoints, :each, :each_byte, :each_char,
   :each_codepoint, :each_line, :eof, :eof?, :external_encoding, :fcntl, :fdatasync, :fileno, :flush,
   :fsync, :getbyte, :getc, :gets, :inspect, :internal_encoding, :ioctl, :isatty, :lineno, :lineno=,
   :lines, :pid, :pos, :pos=, :print, :printf, :putc, :puts, :read, :read_nonblock, :readbyte, :readchar,
   :readline, :readlines, :readpartial, :reopen, :rewind, :seek, :set_encoding, :stat, :sync, :sync=,
   :sysread, :sysseek, :syswrite, :tell, :to_i, :to_io, :tty?, :ungetbyte, :ungetc, :write, :write_nonblock].each do |method|
    define_method(method) do |*args, &block|
      @output.public_send(method, *args, &block)
    end
  end
end