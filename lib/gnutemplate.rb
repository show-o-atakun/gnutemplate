# frozen_string_literal: true

require_relative "gnutemplate/version"
require "numo/gnuplot"
require "histogram/array"

module ExtendNP
  def new_to_iruby
      require 'tempfile'
      tempfile_svg = Tempfile.open(['plot','.svg'])
      # output SVG to tmpfile
      gp = Numo::Gnuplot.default
      gp.reset
      gp.unset :multiplot    # added 
      gp.set terminal:'svg'
      gp.set output:tempfile_svg.path
      gp.instance_eval(&@block)
      ### gp.unset 'output'  # commented out
      svg = File.read(tempfile_svg.path)
      tempfile_svg.close
      ["image/svg+xml",svg]
    end
end

class Numo::Gnuplot::NotePlot
  include ExtendNP
  alias_method :old_to_iruby, :to_iruby
  alias_method :to_iruby, :new_to_iruby
end

module Gnutemplate
  class Error < StandardError; end
  
  
  # settingはむずい
  # ・全体はハッシュ
  # ・基本は次のような指定
  #   settings[:style] = "fill solid" 
  # ・ハッシュを使う場合も。以下は、set :xtic, :rotate, by: rotate_xtics, scale: 0の表現怜
  #   settings[:xtic] = {rotate: nil, by: rotate_xtics, scale: 0}
  # ・同じキー(例えばxtics)に複数指定たいときはリストにして渡す
  #   settings[:xtics] = ["#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}" , 
  #                       "rotate by #{rotate_xtics}"]
  # ・リストの中を更にハッシュにすることも可能
  #   settings[:style] = [{data: nil, histogram: nil},   # set :style, :data, :histogram を表現
  #                       {histogram: nil, cluster: nil, gap: 1},  # set :histogram, :cluster, gap: 1 を表現
  #                       {fill: nil, solid: 1.0 - (alpha/100.0),  border: -1}]

  
  SubPlot = Struct.new(:args, :settings)
  
  def note_line(data)
    Numo.noteplot do
      set xtics: xtics
      set yrange: 0..50
      set :grid
      plot xs, data[0],{w: :linespoints, lc_rgb: "#1199dd", pointtype: 7, pointsize: 0.7, title: 0}, 
          xs, data[1], {w: :linespoints, lc_rgb: "#99dd11", pointtype: 7, pointsize: 0.7, title: 1}
    end
  end

  def draw_line(data)
    Numo.gnuplot do
      set xtics: xtics
      set yrange: 0..50
      set :grid
      plot xs, data[0],{w: :linespoints, lc_rgb: "#1199dd", pointtype: 7, pointsize: 0.7, title: 0}, 
          xs, data[1], {w: :linespoints, lc_rgb: "#99dd11", pointtype: 7, pointsize: 0.7, title: 1}
    end
  end

  def box(rows, titlenames, xrange: nil, xtics: nil, title: nil, file: nil, alpha: 60)

  end

  # 一つのデータで min, max 2列必要とするので
  # rows = [minデータ1, maxデータ1, minデータ2, maxデータ2, ...] という形式で入れてやる
  # xrangeはx軸の範囲(数値..数値の範囲で指定)で、xticsは実際に目盛に表示するラベル(Stringなどの配列)

  def note_box(rows, titlenames, xrange: nil, xtics: nil, title: nil, file: nil, alpha: 60, engine: :note)
    
    # この色をローテーションで使えるようにすれば、何都市でも描けるね、とりあえず
    alpha_hex = (alpha * 256 / 100).to_s(16).upcase
    colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}AAAA00"]
    
    # 列データをmin, maxごとに分離する
    rows_min = (0...(rows.length)).to_a.map {|i| rows[i] if i % 2 == 0}.compact
    rows_max = (0...(rows.length)).to_a.map {|i| rows[i] if i % 2 == 1}.compact
    
    Numo.noteplot do
      if !file.nil?
        set terminal: "gif"
        set output: file
      end

      if !xtics.nil?
        set xtics: xtics 
        set :xtics, "rotate by 90"
      end

      xrange ||= (rows_min.map(&:to_a).flatten.compact.min)..(rows_max.map(&:to_a).flatten.compact.max)
      set xrange: xrange
      set :grid
      set style: :fill_solid
      set title: title if title

      ### キャンドルスティックを応用する
      # X軸, 太い所の最大値, 最大値, 最小値, 太い所の最小値
      # 今回は細い箇所は不要
      # X軸はこの場合配列にしなきゃだめ(to_a) これは癖をつけたほうが安全

      args = rows_min.zip(rows_max, titlenames).each.with_index.inject([]) do |result, ((mi, ma, t), i)|
        result += [xrange.to_a, mi.to_a, mi.to_a, ma.to_a, ma.to_a, {with: "candlesticks", fc_rgb: colors[i % 4], title: t} ]
      end

      plot *args
    end
  end
  
  def draw_box(rows, titlenames, xrange: nil, xtics: nil, title: nil, file: nil, alpha: 60, engine: :note)
    
    # この色をローテーションで使えるようにすれば、何都市でも描けるね、とりあえず
    alpha_hex = (alpha * 256 / 100).to_s(16).upcase
    colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}AAAA00"]
    
    # 列データをmin, maxごとに分離する
    rows_min = (0...(rows.length)).to_a.map {|i| rows[i] if i % 2 == 0}.compact
    rows_max = (0...(rows.length)).to_a.map {|i| rows[i] if i % 2 == 1}.compact

    settings = {}
    args = []

    if !xtics.nil?
      set[:xtics] = [xtics]
      set[:xtics].push "rotate by 90"
    end

    xrange ||= (rows_min.map(&:to_a).flatten.compact.min)..(rows_max.map(&:to_a).flatten.compact.max)
    
    set[:xrange] = xrange
    set[:grid] = nil
    set[:style] = :fill_solid
    set[:title] = title if title

    ### キャンドルスティックを応用する
    # X軸, 太い所の最大値, 最大値, 最小値, 太い所の最小値
    # 今回は細い箇所は不要
    # X軸はこの場合配列にしなきゃだめ(to_a) これは癖をつけたほうが安全

    args = rows_min.zip(rows_max, titlenames).each.with_index.inject([]) do |result, ((mi, ma, t), i)|
      result += [xrange.to_a, mi.to_a, mi.to_a, ma.to_a, ma.to_a, {with: "candlesticks", fc_rgb: colors[i % 4], title: t} ]
    end

    plot *args
  
  end

  # ここからsettings, argsを返せるようにする
  # set terminal部の扱いは考えなければならない(多分、_drow, _noteにif...set...end だけ残せばいい)
  def histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    plotsize: nil, rotate_xtics: 45,
    fill: true, alpha: 33, background: nil,
    file: nil)

    data = [data] if data[0].kind_of?(Numeric) || data[0].nil?

    alpha_hex = (alpha * 256 / 100).to_s(16).upcase
    colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}888800"]

    xmax ||= data.map(&:to_a).flatten.compact.max
    xmin ||= data.map(&:to_a).flatten.compact.min
    freqs = data.map {|d| d.to_a.compact.histogram(bins, min: xmin, max: xmax) }
    ymax ||= freqs.map{ _1[1] }.flatten.max * 1.1

    if pileup

      xticinterval = (xmax-xmin).to_f / bins

      settings = {}
      settings[:size] =  "#{plotsize[0]},#{plotsize[1]}" if plotsize
      settings[:style] = "fill solid" if fill

      settings[:xtics] = ["#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"]
      settings[:xtics].push("rotate by #{rotate_xtics}") if rotate_xtics

      settings[:xrange] = (xmin-xticinterval)..(xmax+xticinterval)
      settings[:yrange] = ymin..ymax

      args = if background
        ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}]
      else
        []
      end

      freqs.each_with_index do |f, i|
        args.push f[0], f[1]

        if labels
          args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
        else
          args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
        end
      end

      return SubPlot.new(args, settings)

    else

      # set title:"Temperature"
      settings = {}
      settings[:auto] = "x"
      settings[:style] = [{data: nil, histogram: nil},   # set :style, :data, :histogram を表現
                          {histogram: nil, cluster: nil, gap: 1},  # set :histogram, :cluster, gap: 1 を表現
                          {fill: nil, solid: 1.0 - (alpha/100.0),  border: -1}]
      settings[:boxwidth] = 0.9
      settings[:xtic] = {rotate: nil, by: rotate_xtics, scale: 0}

      xticinterval = (xmax-xmin).to_f / bins
      settings[:xrange] = 0..((xmax-xmin) / xticinterval).to_i

      xtics = freqs[0][0]
      .each.with_index
      .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
      .gsub(/,$/, ")")
      settings[:xtics] = xtics

      labels ||= (0...(freqs.length)).map(&:to_s)

      args = freqs.zip(labels).each_with_index.map do |(f, l), i|
        [*f, using: 2, w: :histogram, t: labels[i], fillcolor: "rgb \"#{colors[i % 4]}\""]
      end

      return SubPlot.new(args, settings)

    end # Of if pileup..else
  end

  def note_histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    plotsize: nil, rotate_xtics: 45,
    fill: true, alpha: 33, background: nil,
    file: nil)

    as = Gnutemplate.histogram(data, labels: labels, pileup: pileup,
    xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax, bins: bins,
    plotsize: plotsize, rotate_xtics: rotate_xtics,
    fill: fill, alpha: alpha, background: background)
	
    note as, file: file
    
  end # Of def function

  def draw_histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    plotsize: nil, rotate_xtics: 45,
    fill: true, alpha: 33, background: nil,
    file: nil)

    as = Gnutemplate.histogram(data, labels: labels, pileup: pileup,
    xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax, bins: bins,
    plotsize: plotsize, rotate_xtics: rotate_xtics,
    fill: fill, alpha: alpha, background: background)
	
    draw as, file: file

  end # Of def function
  

  def note(subplot, file: nil, campus_size: nil, multicolumn: 1) # for any plot function
	
	subplot = [subplot] if !subplot.is_a?(Array)
	
	Numo.noteplot do

		if file
			if campus_size
				set termnal: "png", size: campus_size
			else
				set terminal: "png"
			end
			set output: file
		end
		
		# マルチプロット調整
		multiline = (subplot.length.to_f / multicolumn).ceil
		set :multiplot, layout: "#{multiline},#{multicolumn}"

		# subplot一つ一つを描画
		subplot.each do |sp|
			
			# こういうのがパターンマッチでできるの？
			sp.settings.each do |k, v|
				if v.kind_of?(Hash)
					sargs = []
					skwargs = {}

					v.map do |vk, vv|
						if vv.nil?
						  sargs.push vk
						else
						  skwargs[vk] = vv
						end
					end
				  
					set k, *sargs, **skwargs

				elsif v.kind_of?(Array)

					v.each do |vi|
						if vi.kind_of?(Hash)
						  sargs = []
						  skwargs = {}
						  vi.map do |vk, vv|
                if vv.nil?
                  sargs.push vk
                else
                  skwargs[vk] = vv
                end
						  end
						  set k, *sargs, **skwargs
						else
						  set k, vi
						end
					end
				  
				else

				  if v.nil?
					  set k
				  else
					  set k, v
				  end

				end
			end

			plot *(sp.args)
		end # of subplot.each
		
		unset :multiplot
	  
	end # of Numo.noteplot
  end # of def draw

  def draw(subplot, file: nil, campus_size: nil, multicolumn: 1) # for any plot function
	
	subplot = [subplot] if !subplot.is_a?(Array)
	
	Numo.gnuplot do

		if file
			if campus_size
				set termnal: "png", size: campus_size
			else
				set terminal: "png"
			end
			set output: file
		end
		
		multiline = (subplot.length.to_f / multicolumn).ceil
		set :multiplot, layout: "#{multiline},#{multicolumn}"

		subplot.each do |sp|
			
			# こういうのがパターンマッチでできるの？
			sp.settings.each do |k, v|
				if v.kind_of?(Hash)
				  sargs = []
				  skwargs = {}
				  
				  v.map do |vk, vv|
            if vv.nil?
              sargs.push vk
            else
              skwargs[vk] = vv
            end
				  end
				  
				  set k, *sargs, **skwargs

				elsif v.kind_of?(Array)

				  v.each do |vi|
            if vi.kind_of?(Hash)
              sargs = []
              skwargs = {}
              vi.map do |vk, vv|
                if vv.nil?
                  sargs.push vk
                else
                  skwargs[vk] = vv
                end
              end
              set k, *sargs, **skwargs
            else
              set k, vi
            end
				  end
				  
				else

				  if v.nil?
					  set k
				  else
					  set k, v
				  end

				end
			end
			
			plot *(sp.args)
		
		end # of subplot.each
		
		unset :multiplot
		
    end # of Numo.gnuplot
  end # of def draw
	
  module_function :histogram
  module_function :note_line, :draw_line
  module_function :note_box, :draw_box
  module_function :note_histogram, :draw_histogram
  module_function :note, :draw

end # Of module
