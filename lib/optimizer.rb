require 'tempfile'

module Optimizer

  @exec = Opentour::Application.config.optimizer_exec
  @tmp_dir = Opentour::Application.config.optimizer_tmp_dir

  def self.optimize(number, matrix)
    input = Tempfile.new('optimize-route-input', tmpdir=@tmp_dir)
    output = Tempfile.new('optimize-route-output', tmpdir=@tmp_dir)

    begin
      output.close

      input.write("NAME : openroute
TYPE : ATSP
DIMENSION : #{matrix.size}
EDGE_WEIGHT_TYPE: EXPLICIT
EDGE_WEIGHT_FORMAT: FULL_MATRIX
EDGE_WEIGHT_SECTION
")
      input.write(matrix.collect{ |a| a.join(" ") }.join("\n"))
      input.write("\nEOF\n")

      input.close

      `cat #{input.path} > /tmp/in` # FIXME tmp
      `cat #{output.path} > /tmp/out` # FIXME tmp
      cmd = "#{@exec} -tsp_time_limit_in_ms 2000 -instance_file '#{input.path}' > '#{output.path}'"
      Rails.logger.info(cmd)
      system(cmd)
      Rails.logger.info($?.exitstatus)
      if $?.exitstatus == 0
        result = File.read(output.path)
        result = result.split("\n")[-1]
        Rails.logger.info result.inspect
        result.split(' ').collect{ |i| Integer(i) }
      end
    ensure
      input.unlink
      output.unlink
    end
  end
end
