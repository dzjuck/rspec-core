module RSpec::Core
  RSpec.describe OutputWrapper do
    let(:output) { double('IO') }
    let(:wrapper) { OutputWrapper.new(output) }

    describe '#output=' do
      let(:another_output) { StringIO.new }

      it 'changes the output stream' do
        wrapper.output = another_output
        expect(wrapper.output).to eq(another_output)
      end
    end

    [:binmode, :binmode?, :bytes, :chars, :close, :close_on_exec=,
     :close_on_exec?, :close_read, :close_write, :closed?, :codepoints, :each, :each_byte, :each_char,
     :each_codepoint, :each_line, :eof, :eof?, :external_encoding, :fcntl, :fdatasync, :fileno, :flush,
     :fsync, :getbyte, :getc, :gets, :inspect, :internal_encoding, :ioctl, :isatty, :lineno, :lineno=,
     :lines, :pid, :pos, :pos=, :print, :printf, :putc, :puts, :read, :read_nonblock, :readbyte, :readchar,
     :readline, :readlines, :readpartial, :reopen, :rewind, :seek, :set_encoding, :stat, :sync, :sync=,
     :sysread, :sysseek, :syswrite, :tell, :to_i, :to_io, :tty?, :ungetbyte, :ungetc, :write, :write_nonblock].each do |method|
      describe "##{method}" do
        let(:block) { Proc.new { 'test block' } }

        it "calls output's '#{method}' with the same params" do
          expect(output).to receive(method).with('all', 'args')
          wrapper.send(method, 'all', 'args')
        end
        it "calls output's '#{method}' with the same params and block" do
          expect(output).to receive(method).with('all', 'args', &block)
          wrapper.send(method, 'all', 'args', &block)
        end
      end
    end

  end
end
