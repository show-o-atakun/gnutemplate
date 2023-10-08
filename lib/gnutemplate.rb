# frozen_string_literal: true

require_relative "gnutemplate/version"
require "numo/gnuplot"

module Gnutemplate
  class Error < StandardError; end
  # Your code goes here...

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

      xrange ||= (rows_min.flatten.compact.min)..(rows_max.flatten.compact.max)
      set xrange: xrange
      set :grid
      set style: :fill_solid
      set title: title if title

      ### キャンドルスティックを応用する
      # X軸, 太い所の最大値, 最大値, 最小値, 太い所の最小値
      # 今回は細い箇所は不要
      # X軸はこの場合配列にしなきゃだめ(to_a) これは癖をつけたほうが安全

      args = rows_min.zip(rows_max, titlenames).each.with_index.inject([]) do |result, ((mi, ma, t), i)|
        result += [xrange.to_a, mi, mi, ma, ma, {with: "candlesticks", fc_rgb: colors[i % 4], title: t} ]
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

      xrange ||= (rows_min.flatten.compact.min)..(rows_max.flatten.compact.max)
      set xrange: xrange
      set :grid
      set style: :fill_solid
      set title: title if title

      ### キャンドルスティックを応用する
      # X軸, 太い所の最大値, 最大値, 最小値, 太い所の最小値
      # 今回は細い箇所は不要
      # X軸はこの場合配列にしなきゃだめ(to_a) これは癖をつけたほうが安全

      args = rows_min.zip(rows_max, titlenames).each.with_index.inject([]) do |result, ((mi, ma, t), i)|
        result += [xrange.to_a, mi, mi, ma, ma, {with: "candlesticks", fc_rgb: colors[i % 4], title: t} ]
      end

      plot *args
    end
  end


  def note_histograms(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    figsize: 1.0, rotate_xtics: nil,
    fill: true, alpha: 33, background: nil,
    file: nil, engine: :note)

    # 色の定義
    alpha_hex = (alpha * 256 / 100).to_s(16).upcase
    colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}888800"]

    # 描画元データ定義
    xmax ||= data.flatten.max
    xmin ||= data.flatten.min
    freqs = data.map {|d| d.histogram(bins, min: xmin, max: xmax) }
    ymax ||= freqs.map{ _1[1] }.flatten.max * 1.1

    Numo.noteplot do

      # 画像出力先
      if !file.nil?
        set terminal: "gif"
        set output: file
      end

      if pileup
        ###########
        ### 重ねる
        ###########

        # 軸などの設定
        set size: "#{figsize},#{figsize}"  # またはset size: "ratio 0.4" など
        set style: "fill solid" if fill

        xticinterval = (xmax-xmin).to_f / bins
        set xtics: "#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"
        set(:xtics, "rotate by #{rotate_xtics}") if rotate_xtics

        set xrange: (xmin-xticinterval)..(xmax+xticinterval)
        set yrange: ymin..ymax

        # まず初期の引数配列をつくり
        args = background ? ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}] : []

        # あとは回していく感じか
        freqs.each_with_index do |f, i|
          args.push f[0], f[1]

          # ラベルありなしで渡す引数を変える
          if labels
            args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
          else
            args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
          end
        end

        plot *args # ,xs, ys, { with: :lines , title: "STD"}  # 例えばこう足せば折れ線グラフと重ねられる

      else

        ###########
        ### 並べる
        ###########
        # set title:"Temperature"
        set auto:"x"
        set :style, :data, :histogram
        set :style, :histogram, :cluster, gap:1
        set :style, :fill_solid, border:-1
        set boxwidth:0.9
        set :xtic, :rotate, by:-45, scale:0

        # このレンジ・軸ラベル設定が味噌
        # w: histogramはどうやっても x軸が0スタートになってしまう。
        # そこであきらめてxrangeは0を最低とする
        xticinterval = (xmax-xmin).to_f / bins
        set xrange: 0..((xmax-xmin) / xticinterval).to_i

        # そして、xticsの方で頑張って見かけ上の表示を置換してあげる
        ## set xtics: "(5 0, 6 1)" ←変換例 x=0に 5 と表示し、x=1に 6 と表示する。では実践

        xtics = freqs[0][0]
        .each.with_index
        .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
        .gsub(/,$/, ")")
        set xtics: xtics

        plot [*freqs[0], using: 2, w: :histogram, t: labels[0], fillcolor: "rgb \"#{colors[0 % 4]}\""],
        [*freqs[1], using: 2, w: :histogram, t: labels[1], fillcolor: "rgb \"#{colors[1 % 4]}\""],
        [*freqs[2], using: 2, w: :histogram, t: labels[2], fillcolor: "rgb \"#{colors[2 % 4]}\""]
      end # Of if pileup..else
    end # Of Numo.noteplot do

  end # Of def function

  def draw_histograms(data, labels: nil, pileup: true,
    xmin: nil, xmax: nil, ymin: 0, ymax: nil, bins: 10,
    figsize: 1.0, rotate_xtics: nil,
    fill: true, alpha: 33, background: nil,
    file: nil, engine: :note)

    # 色の定義
    alpha_hex = (alpha * 256 / 100).to_s(16).upcase
    colors = ["##{alpha_hex}CC0000", "##{alpha_hex}00CC00", "##{alpha_hex}0000CC", "##{alpha_hex}888800"]

    # 描画元データ定義
    xmax ||= data.flatten.max
    xmin ||= data.flatten.min
    freqs = data.map {|d| d.histogram(bins, min: xmin, max: xmax) }
    ymax ||= freqs.map{ _1[1] }.flatten.max * 1.1

    Numo.gnuplot do

      # 画像出力先
      if !file.nil?
        set terminal: "gif"
        set output: file
      end

      if pileup
        ###########
        ### 重ねる
        ###########

        # 軸などの設定
        set size: "#{figsize},#{figsize}"  # またはset size: "ratio 0.4" など
        set style: "fill solid" if fill

        xticinterval = (xmax-xmin).to_f / bins
        set xtics: "#{xmin-xticinterval}, #{xticinterval}, #{xmax+xticinterval}"
        set(:xtics, "rotate by #{rotate_xtics}") if rotate_xtics

        set xrange: (xmin-xticinterval)..(xmax+xticinterval)
        set yrange: ymin..ymax

        # まず初期の引数配列をつくり
        args = background ? ["[#{xmin}:#{xmax}] #{ymax} with filledc above y=#{ymin} fc \"##{background}\" notitle", {}] : []

        # あとは回していく感じか
        freqs.each_with_index do |f, i|
          args.push f[0], f[1]

          # ラベルありなしで渡す引数を変える
          if labels
            args.push({:with => :boxes, :title => labels[i], :fillcolor => "rgb \"#{colors[i % 4]}\""})
          else
            args.push({:with => :boxes, :fillcolor => "rgb \"#{colors[i % 4]}\""})
          end
        end

        plot *args # ,xs, ys, { with: :lines , title: "STD"}  # 例えばこう足せば折れ線グラフと重ねられる

      else

        ###########
        ### 並べる
        ###########
        # set title:"Temperature"
        set auto:"x"
        set :style, :data, :histogram
        set :style, :histogram, :cluster, gap:1
        set :style, :fill_solid, border:-1
        set boxwidth:0.9
        set :xtic, :rotate, by:-45, scale:0

        # このレンジ・軸ラベル設定が味噌
        # w: histogramはどうやっても x軸が0スタートになってしまう。
        # そこであきらめてxrangeは0を最低とする
        xticinterval = (xmax-xmin).to_f / bins
        set xrange: 0..((xmax-xmin) / xticinterval).to_i

        # そして、xticsの方で頑張って見かけ上の表示を置換してあげる
        ## set xtics: "(5 0, 6 1)" ←変換例 x=0に 5 と表示し、x=1に 6 と表示する。では実践

        xtics = freqs[0][0]
        .each.with_index
        .inject("(") { |result, (x, i)| result += "'#{x-xticinterval/2}-#{x+xticinterval/2}' #{i}," }
        .gsub(/,$/, ")")
        set xtics: xtics

        plot [*freqs[0], using: 2, w: :histogram, t: labels[0], fillcolor: "rgb \"#{colors[0 % 4]}\""],
        [*freqs[1], using: 2, w: :histogram, t: labels[1], fillcolor: "rgb \"#{colors[1 % 4]}\""],
        [*freqs[2], using: 2, w: :histogram, t: labels[2], fillcolor: "rgb \"#{colors[2 % 4]}\""]
      end # Of if pileup..else
    end # Of Numo.noteplot do

  end # Of def function
end # Of module
