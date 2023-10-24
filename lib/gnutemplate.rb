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
    
    Numo.gnuplot do
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

  # いずれかはここからargsを返せるようにする
  # set terminal部の扱いは考えなければならない(多分、_drow, _noteにif...set...end だけ残せばいい)
  def histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    figsize: 1.0, rotate_xtics: 45,
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
      ###########
      ### 
      ###########

      set size: "#{figsize},#{figsize}"  
      set style: "fill solid" if fill

      xticinterval = (xmax-xmin).to_f / bins
      set xtics: "#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"
      set(:xtics, "rotate by #{rotate_xtics}") if rotate_xtics

      set xrange: (xmin-xticinterval)..(xmax+xticinterval)
      set yrange: ymin..ymax

      args = background ? ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}] : []

      freqs.each_with_index do |f, i|
        args.push f[0], f[1]

        if labels
          args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
        else
          args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
        end
      end

      return args 

    else

      ###########
      ### 
      ###########
      # set title:"Temperature"
      set auto:"x"
      set :style, :data, :histogram
      set :style, :histogram, :cluster, gap:1
      set :style, :fill, solid: 1.0 - (alpha/100.0),  border:-1
      set boxwidth:0.9
      set :xtic, :rotate, by: rotate_xtics, scale: 0

      xticinterval = (xmax-xmin).to_f / bins
      set xrange: 0..((xmax-xmin) / xticinterval).to_i

      xtics = freqs[0][0]
      .each.with_index
      .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
      .gsub(/,$/, ")")
      set xtics: xtics

      labels ||= (0...(freqs.length)).map(&:to_s)

      args = freqs.zip(labels).each_with_index.map do |(f, l), i|
        [*f, using: 2, w: :histogram, t: labels[i], fillcolor: "rgb \"#{colors[i % 4]}\""]
      end

      return args

    end # Of if pileup..else
  end
  module_function :histogram

  def note_histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    figsize: 1.0, rotate_xtics: 45,
    fill: true, alpha: 33, background: nil,
    file: nil)

    Numo.noteplot do

      if !file.nil?
        set terminal: "gif"
        set output: file
      end
      
      args = Gnutemplate.histogram(data, labels: labels, pileup: pileup,
      xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax, bins: bins,
      figsize: figsize, rotate_xtics: rotate_xtics,
      fill: fill, alpha: alpha, background: background)

      plot *args

      # data = [data] if data[0].kind_of?(Numeric) || data[0].nil?

      # alpha_hex = (alpha * 256 / 100).to_s(16).upcase
      # colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}888800"]
  
      # xmax ||= data.map(&:to_a).flatten.compact.max
      # xmin ||= data.map(&:to_a).flatten.compact.min
      # freqs = data.map {|d| d.to_a.compact.histogram(bins, min: xmin, max: xmax) }
      # ymax ||= freqs.map{ _1[1] }.flatten.max * 1.1


      # if pileup
      #   ###########
      #   ### 
      #   ###########

      #   set size: "#{figsize},#{figsize}"  
      #   set style: "fill solid" if fill

      #   xticinterval = (xmax-xmin).to_f / bins
      #   set xtics: "#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"
      #   set(:xtics, "rotate by #{rotate_xtics}") if rotate_xtics

      #   set xrange: (xmin-xticinterval)..(xmax+xticinterval)
      #   set yrange: ymin..ymax

      #   args = background ? ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}] : []

      #   freqs.each_with_index do |f, i|
      #     args.push f[0], f[1]

      #     if labels
      #       args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
      #     else
      #       args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
      #     end
      #   end

      #   plot *args 

      # else

      #   ###########
      #   ### 
      #   ###########
      #   # set title:"Temperature"
      #   set auto:"x"
      #   set :style, :data, :histogram
      #   set :style, :histogram, :cluster, gap:1
      #   set :style, :fill, solid: 1.0 - (alpha/100.0),  border:-1
      #   set boxwidth:0.9
      #   set :xtic, :rotate, by: rotate_xtics, scale: 0

      #   xticinterval = (xmax-xmin).to_f / bins
      #   set xrange: 0..((xmax-xmin) / xticinterval).to_i

      #   xtics = freqs[0][0]
      #   .each.with_index
      #   .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
      #   .gsub(/,$/, ")")
      #   set xtics: xtics

      #   labels ||= (0...(freqs.length)).map(&:to_s)

      #   args = freqs.zip(labels).each_with_index.map do |(f, l), i|
      #     [*f, using: 2, w: :histogram, t: labels[i], fillcolor: "rgb \"#{colors[i % 4]}\""]
      #   end

      #   plot *args

      # end # Of if pileup..else

    end # Of Numo.noteplot do

  end # Of def function

  def draw_histogram(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    figsize: 1.0, rotate_xtics: 45,
    fill: true, alpha: 33, background: nil,
    file: nil)

    Numo.gnuplot do

      if !file.nil?
        set terminal: "gif"
        set output: file
      end
      
      args = Gnutemplate.histogram(data, labels: labels, pileup: pileup,
      xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax, bins: bins,
      figsize: figsize, rotate_xtics: rotate_xtics,
      fill: fill, alpha: alpha, background: background)

      plot *args

      # data = [data] if data[0].kind_of?(Numeric) || data[0].nil?

      # alpha_hex = (alpha * 256 / 100).to_s(16).upcase
      # colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}888800"]
  
      # xmax ||= data.map(&:to_a).flatten.compact.max
      # xmin ||= data.map(&:to_a).flatten.compact.min
      # freqs = data.map {|d| d.to_a.compact.histogram(bins, min: xmin, max: xmax) }
      # ymax ||= freqs.map{ _1[1] }.flatten.max * 1.1

      # if pileup
      #   ###########
      #   ### 
      #   ###########

      #   set size: "#{figsize},#{figsize}"  
      #   set style: "fill solid" if fill

      #   xticinterval = (xmax-xmin).to_f / bins
      #   set xtics: "#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"
      #   set(:xtics, "rotate by #{rotate_xtics}") if rotate_xtics

      #   set xrange: (xmin-xticinterval)..(xmax+xticinterval)
      #   set yrange: ymin..ymax

      #   args = background ? ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}] : []

      #   freqs.each_with_index do |f, i|
      #     args.push f[0], f[1]

      #     if labels
      #       args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
      #     else
      #       args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
      #     end
      #   end

      #   plot *args # ,xs, ys, { with: :lines , title: "STD"}  

      # else

      #   ###########
      #   ### 
      #   ###########
      #   set auto:"x"
      #   set :style, :data, :histogram
      #   set :style, :histogram, :cluster, gap:1
      #   set :style, :fill, solid: 1.0 - (alpha/100.0),  border:-1
      #   set boxwidth:0.9
      #   set :xtic, :rotate, by: rotate_xtics, scale: 0

      #   xticinterval = (xmax-xmin).to_f / bins
      #   set xrange: 0..((xmax-xmin) / xticinterval).to_i

      #   xtics = freqs[0][0]
      #   .each.with_index
      #   .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
      #   .gsub(/,$/, ")")
      #   set xtics: xtics

      #   labels ||= (0...(freqs.length)).map(&:to_s)

      #   args = freqs.zip(labels).each_with_index.map do |(f, l), i|
      #     [*f, using: 2, w: :histogram, t: labels[i], fillcolor: "rgb \"#{colors[i % 4]}\""]
      #   end

      #   plot *args
      
      # end # Of if pileup..else
    end # Of Numo.gnuplot do

  end # Of def function

  module_function :note_line, :draw_line, :note_box, :draw_box, :note_histogram, :draw_histogram
end # Of module
