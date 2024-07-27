#!/usr/bin/env ruby

# This is basically a 1:1 translation of the notcurses-demo which should
# theoretically test all features.
require 'atomic'
require 'notcurses'

include Notcurses

# Structs, some in demo.c some from demo.h
Demo = Struct.new(:name, :fxn, :dfsg_disabled)
DemoResult = Struct.new(:selector, :stats, :timens, :result)
TimeSpec = Struct.new(:tv_sec, :tv_nsec)

# Constants
DEFAULT_DEMO = "ixetunchdmbkywjgarvlsfqzo".each_char.to_a.freeze
EXIT_SUCCESS = 0
EXIT_FAILURE = 1

# (non-)ansi terminal definition-4-life
MIN_SUPPORTED_ROWS = 24
MIN_SUPPORTED_COLS = 76 # allow a bit of margin, sigh

# Obviously using globals like this isn't idiomatic Ruby, the point is to
# stray as little as possible from the demo C code to test the extension.
$datadir = String.new
$delaymultiplier = Float.new(1)
$democount = DEFAULT_DEMO.size

# scaled in getopt() by delaymultiplier
$demodelay = TimeSpec.new(tv_sec: 1, tv_nsec: 0)

$opts = { }
$interrupted = Atomic.new(false)
$restart_demos = Atomic.new(false)
$results = [ ]

def interrupt_demo
  $interrupted = true
end

def interrupt_and_restart_demos
  $restart_demos = true
  $interrupted = true
end

def demoresult_lookup(idx)
  return nil if idx.negative? || idx > $democount
  $results[idx]
end

def find_data(datum)
  notcurses_data_path($datadir, datum)
end

# the "jungle" demo has non-free material embedded into it, and is thus
# entirely absent (can't just be disabled). supply a stub here.
def jungle_demo(nc, startns)
  return -1
end

$demos = [
  Demo.new(name: "animate", fxn: animate_demo, dfsg_disabled: false, ),
  Demo.new(name: "box", fxn: box_demo, dfsg_disabled: false, ),
  Demo.new(name: "chunli", fxn: chunli_demo, dfsg_disabled: true, ),
  Demo.new(name: "dragon", fxn: dragon_demo, dfsg_disabled: false, ),
  Demo.new(name: "eagle", fxn: eagle_demo, dfsg_disabled: true, ),
  Demo.new(name: "fission", fxn: fission_demo, dfsg_disabled: false, ),
  Demo.new(name: "grid", fxn: grid_demo, dfsg_disabled: false, ),
  Demo.new(name: "highcon", fxn: highcon_demo, dfsg_disabled: false, ),
  Demo.new(name: "intro", fxn: intro_demo, dfsg_disabled: false, ),
  Demo.new(name: "jungle", fxn: jungle_demo, dfsg_disabled: true, ),
  Demo.new(name: "keller", fxn: keller_demo, dfsg_disabled: true, ),
  Demo.new(name: "luigi", fxn: luigi_demo, dfsg_disabled: true, ),
  Demo.new(name: "mojibake", fxn: mojibake_demo, dfsg_disabled: false, ),
  Demo.new(name: "normal", fxn: normal_demo, dfsg_disabled: false, ),
  Demo.new(name: "outro", fxn: outro_demo, dfsg_disabled: false, ),
  Demo.new(name: nil, fxn: nil, dfsg_disabled: false, ), # it's a secret to everyone
  Demo.new(name: "qrcode", fxn: qrcode_demo, dfsg_disabled: false, ), # is blank without USE_QRCODEGEN
  Demo.new(name: "reel", fxn: reel_demo, dfsg_disabled: false, ),
  Demo.new(name: "sliders", fxn: sliders_demo, dfsg_disabled: false, ),
  Demo.new(name: "trans", fxn: trans_demo, dfsg_disabled: false, ),
  Demo.new(name: "uniblock", fxn: uniblock_demo, dfsg_disabled: false, ),
  Demo.new(name: "view", fxn: view_demo, dfsg_disabled: true, ),
  Demo.new(name: "whiteout", fxn: whiteout_demo, dfsg_disabled: false, ),
  Demo.new(name: "xray", fxn: xray_demo, dfsg_disabled: false, ),
  Demo.new(name: "yield", fxn: yield_demo, dfsg_disabled: false, ),
  Demo.new(name: "zoo", fxn: zoo_demo, dfsg_disabled: false, ),
]

def usage_option(ncplane, opstr)
  ncplane_set_fg_rgb8(ncplane, 0x80, 0x80, 0x80)
  ncplane_printf(ncplane, " [ ")
  ncplane_set_fg_rgb8(ncplane, 0xff, 0xff, 0x80)
  ncplane_printf(ncplane, "%s", opstr)
  ncplane_set_fg_rgb8(ncplane, 0x80, 0x80, 0x80)
  ncplane_printf(ncplane, " ] ")
  ncplane_set_fg_rgb8(ncplane, 0xff, 0xff, 0xff)
end

def usage_expo(ncplane, opstr, expostr)
  ncplane_set_fg_rgb8(ncplane, 0xff, 0xff, 0x80)
  ncplane_printf(ncplane, " %s: ", opstr)
  ncplane_set_fg_rgb8(ncplane, 0xff, 0xff, 0xff)
  ncplane_printf(ncplane, "%s\n", expostr)
end

def usage(exestr, status)
  out = status == EXIT_SUCCESS ? STDOUT : STDERR
  opts = NotcursesOptions.new
  opts.flags = NCOPTION_CLI_MODE | NCOPTION_DRAIN_INPUT | NCOPTION_SUPPRESS_BANNERS
  nc = notcurses_init(opts, out)
  exit status if nc.nil?

  n = notcurses_stdplane(nc)

  ncplane_set_fg_rgb8(n, 0x00, 0xc0, 0xc0)
  ncplane_putstr(n, "usage: ")
  ncplane_set_fg_rgb8(n, 0x80, 0xff, 0x80)
  ncplane_printf(n, "%s ", exestr)

  options = [
    "-hVkc",
    "-m margins",
    "-p path",
    "-l loglevel",
    "-d mult",
    "-J jsonfile",
    "demospec",
  ]

  options.each { |opt| usage_option(n, opt) }

  ncplane_putstr(n, "\n\n")
  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0xff)

  optexpo = {
    "-h|--help" => "this message",
    "-V|--version" => "print program name and version",
    "-k" => "keep screen; do not switch to alternate",
    "-d" => "delay multiplier (non-negative float)",
    "-J" => "emit JSON summary to file",
    "-c" => "constant PRNG seed, useful for benchmarking",
    "-m" => "margin, or 4 comma-separated margins",
  }

  optexpo.each { |k, v| usage_expo(n, k, v) }

  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0x80)
  ncplane_printf(n, " -l:")
  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0xff)
  ncplane_printf(n, " logging level (%d: silent..%d: manic)\n", NCLOGLEVEL_SILENT, NCLOGLEVEL_TRACE)
  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0x80)
  ncplane_printf(n, " -p:")
  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0xff)
  ncplane_printf(n, " data file path (default: %s)\n", notcurses_data_dir())
  ncplane_printf(n, "\nspecify demos via their first letter. repetitions are allowed.\n")
  ncplane_set_fg_rgb8(n, 0x80, 0xff, 0x80)
  ncplane_printf(n, " default spec: %s\n\n", DEFAULT_DEMO)
  ncplane_set_fg_rgb8(n, 0xff, 0xff, 0xff)

  printed = 0

  $demos.each do |demo|
    next unless demo.name

    ncplane_printf(n, " ") if printed % 5 == 0

    # U+24D0: CIRCLED LATIN SMALL LETTER A
    ncplane_set_fg_rgb8(n, 0xff, 0xff, 0x80)
    ncplane_printf(n, "%lc ", (demo.name[0].ord - 'a'.ord + 0x24d0))
    ncplane_set_fg_rgb8(n, 0xff, 0xff, 0xff)
    ncplane_printf(n, "%-*.*s", 8, 8, demo.name[1..])

    ncplane_printf(n, "\n") if ((printed += 1) % 5 == 0)
  end

  ncplane_printf(n, "\n") if printed % 5
  notcurses_render(nc)
  notcurses_stop(nc)

  exit status
end

def ext_demos(nc, specstr)
  ret = 0
  char_arr = specstr.each_char.to_a

  char_arr.size.times do
    $results << DemoResult.new
  end

  $democount = char_arr.size

  prevns = Process.clock_gettime(
    Process::CLOCK_MONOTONIC,
    :nanosecond
  ).to_i

  char_arr.each_with_index { |ch, idx| $results[idx].selector = ch }

  n = notcurses_stdplane(nc)

  char_arr.each_with_index do |ch, idx|
    break if $interrupted

    # I don't rly understand the point of this in the original code, but doing
    # it anyway.
    demo_idx = ch.ord - 'a'.ord
    next if $demos[demo_idx]&.dfsg_disabled

    # set the standard plane's base character to an opaque black, but don't
    # erase the plane (we let one demo bleed through to the next, an effect
    # we exploit in a few transitions).
    stdc = ncchannels_initializer(0, 0, 0, 0, 0, 0)
    ncplane_set_base(n, "", 0, stdc)
    hud_schedule($demos[demo_idx].name, prevns)
    ret = $demos[demo_idx].fxn.call(nc, prevns)
    notcurses_stats_reset(nc, $results[idx].stats)
    nowns = Process.clock_gettime(
      Process::CLOCK_MONOTONIC,
      :nanosecond
    ).to_i
    $results[idx].timens = nowns - prevns
    prevns = nowns
    $results[idx].result = ret
    hud_completion_notify($results[idx])
    break unless ret.zero?
  end

  0
end

# returns the demos to be run as a string. on error, returns nil. on no
# specification, also returns nil, heh. determine this by argv[optind];
# if it's nil, there were valid options, but no spec.
# Edited this one pretty heavily to use Ruby's OptionParser inttead of
# the classic C getopt.
def handle_opts(argc, argv, opts, json_output_file = nil)
  constant_seed = false

  OptionParser.new do |parser|
    parser.banner = "Usage: #{argv[0]} [options]"

    parser.on('-h', '--help', 'Display this help') do
      puts parser
      exit EXIT_SUCCESS
    end

    parser.on('-V', '--version', 'Display version information') do
      puts "Notcurses version #{notcurses_version}"
      exit EXIT_SUCCESS
    end

    parser.on('-l LEVEL', Integer, 'Set log level') do |loglevel|
      opts[:loglevel] = loglevel
      if opts[:loglevel] < NCLOGLEVEL_SILENT || opts[:loglevel] > NCLOGLEVEL_TRACE
        warn "Invalid log level: #{opts[:loglevel]}"
        puts parser
        exit EXIT_FAILURE
      end
    end

    parser.on('-m MARGINS', 'Set margins') do |margin_str|
      if opts[:margin_t] || opts[:margin_r] || opts[:margin_b] || opts[:margin_l]
        warn "Provided margins twice!"
        puts parser
        exit EXIT_FAILURE
      end
      if notcurses_lex_margins(margin_str, opts) != 0
        puts parser
        exit EXIT_FAILURE
      end
    end

    parser.on('-J FILE', 'Specify JSON output file') do |file|
      if json_output_file
        warn "Supplied -J twice: #{file}"
        puts parser
        exit EXIT_FAILURE
      end
      begin
        json_output_file = File.open(file, 'wb')
      rescue SystemCallError => e
        warn "Error opening #{file} for JSON (#{e.message})"
        puts parser
        exit EXIT_FAILURE
      end
    end

    parser.on('-c', 'Use constant seed') do
      constant_seed = true
    end

    parser.on('-k', 'No alternate screen') do
      opts[:flags] |= NCOPTION_NO_ALTERNATE_SCREEN
    end

    parser.on('-p DIR', 'Set data directory') do |dir|
      $datadir = dir
    end

    parser.on('-d FLOAT', Float, 'Set delay multiplier') do |f|
      if f < 0
        warn "Invalid multiplier: #{f}"
        puts parser
        exit EXIT_FAILURE
      end
      $delaymultiplier = f
      ns = (f * NANOSECS_IN_SEC).to_i
      $demodelay[:tv_sec] = ns / NANOSECS_IN_SEC
      $demodelay[:tv_nsec] = ns % NANOSECS_IN_SEC
    end
  end.parse!(argv)

  srand(Time.now.to_i) unless constant_seed

  if argv.size > 1
    warn "Extra argument: #{argv[1]}"
    puts parser
    exit EXIT_FAILURE
  end

  datadir ||= notcurses_data_dir

  spec = argv[0]
  spec
end

def table_segment_color(n, str, delim, ascdelim, color)
  ncplane_set_fg_rgb(n, color)
  return -1 if ncplane_putstr(n, str).negative?
  ncplane_set_fg_rgb8(n, 178, 102, 255)
  truedelim = notcurses_canutf8(ncplane_notcurses(n)) ? delim : ascdelim
  ncplane_putstr(n, truedelim)
end

def table_segment(n, str, deim, ascdelim)
  table_segment_color(n, str, delim, ascdelim, 0xffffff)
end

def table_printf(n, delim, fmt, *args)
  ncplane_set_fg_rgb8(n, 0xD4, 0xAF, 0x37)
  r = ncplane_vprintf(n, fmt, *args)
  ncplane_set_fg_rgb8(n, 178, 102, 255)
  ncplane_putstr(n, delim)
  r
end

def summary_json(f, spec, rows, cols)
  json_data = {
    'notcurses-demo' => {
      'spec' => spec,
      'TERM' => ENV['TERM'],
      'rows' => rows.to_s,
      'cols' => cols.to_s,
      'runs' => {}
    }
  }

  spec.each_char.with_index do |char, i|
    selector = char.ord - 'a'.ord
    next if results[i].result || results[i].stats.renders.zero?

    json_data['notcurses-demo']['runs'][demos[selector].name] = {
      'bytes' => results[i].stats.raster_bytes.to_s,
      'frames' => results[i].stats.renders.to_s,
      'ns' => results[i].timens.to_s
    }
  end

  f.puts JSON.generate(json_data)
  0
rescue StandardError => e
  warn "Error in summary_json: #{e.message}"
  1
end

def summary_table(nc, spec, canimage, canvideo)
  notcurses_leave_alternate_screen(nc)
  n = notcurses_stdplane(nc)
  ncplane_set_bg_default(n)
  ncplane_set_scrolling(n, true)
  failed = false
  totalbytes = 0
  totalframes = 0
  ncplane_putchar(n, '\n')
  notcurses_render(nc);
  sep = "|"

  table_segment(n, "             runtime", "│", "|")
  table_segment(n, " frames", "│", "|")
  table_segment(n, "output(B)", "│", "|")
  table_segment(n, "    FPS", "│", "|")
  table_segment(n, "%r", "│", "|")
  table_segment(n, "%a", "│", "|")
  table_segment(n, "%w", "│", "|")
  table_segment(
    n,
    "TheoFPS",
    "║\n══╤════════╤════════╪═══════╪═════════╪═══════╪══╪══╪══╪═══════╣\n",
    "|\n--+--------+--------+-------+---------+-------+--+--+--+-------|\n",
  )

  timebuf = Array.new(NCPREFIXSTRLEN + 1)
  tfpsbuf = Array.new(NCPREFIXSTRLEN + 1)
  totalbuf = Array.new(NCBPREFIXSTRLEN + 1)
  nsdelta = 0

  spec.each_char.to_a.size.times do |i|
    nsdelta += $results[i].timens
    ncqprefix($results[i].timens, NANOSECS_IN_SEC, timebuf, 0)
    ncbprefix($results[i].stats.raster_bytes, 1, totalbuf, 0)

    divisor = $results[i].stats.render_ns
    divisor += $results[i].stats.writeout_ns
    divisor += $results[i].stats.raster_ns

    ncqprefix(0, NANOSECS_IN_SEC, tfpsbuf, 0) if divisor.zero?
    unless divisor.zero?
      ncqprefix(
        $results[i].stats.writeouts * NANOSECS_IN_SEC * 1000 / divisor,
        1000,
        tfpsbuf,
        0,
      )
    end

    rescolor = case
      when $results[i].result.negative?
        0xff303c
      when $results[i].result.positive?
        0xffaa22
      when $results[i].stats.renders.zero?
        0xbbbbbb
      else
        0x32CD32
    end

    ncplane_set_fg_rgb(n, rescolor)
    ncplane_printf(n, "%2llu", i + 1) # windows has %zu problems
    ncplane_set_fg_rgb8(n, 178, 102, 255)
    ncplane_putegc(n, sep, nil)
    ncplane_set_fg_rgb(n, rescolor)
    ncplane_printf(n, "%8s", demos[$results[i].selector - 'a'].name)
    ncplane_set_fg_rgb8(n, 178, 102, 255)

    ncplane_printf(
      n,
      "%s%*ss%s%7%#{PRIu64}%s%*s%s%7.1f%s%2%#{PRId64}%s%2%#{PRId64}%s%2%#{PRId64}%s%*s%s",
      sep,
      ncprefixfmt(timebuf),
      timebuf,
      sep,
      $results[i].stats.renders,
      sep,
      ncbprefixfmt(totalbuf),
      totalbuf,
      sep,
      $results[i].timens ? $results[i].stats.renders / ($results[i].timens / NANOSECS_IN_SEC) : 0.0,
      sep,
      $results[i].timens ? $results[i].stats.render_ns * 100 / $results[i].timens : 0,
      sep,
      $results[i].timens ? $results[i].stats.raster_ns * 100 / $results[i].timens : 0,
      sep,
      $results[i].timens ? $results[i].stats.writeout_ns * 100 / $results[i].timens : 0,
      sep,
      ncprefixfmt(tfpsbuf),
      tfpsbuf,
      notcurses_canutf8(ncplane_notcurses(n)) ? "║" : "|",
    )

    ncplane_set_fg_rgb(n, rescolor)
    output_str = case
      when $results[i].result.negative?
        "FAILED"
      when $results[i].result.positive?
        "ABORTED"
      when !$results[i].stats.renders
        "SKIPPED"
      else
        ""
    end

    ncplane_printf(n, "%s\n", output_str)

    failed = $results[i].result.negative? ? true : false
    totalframes += $results[i].stats.renders
    totalbytes += $results[i].stats.raster_bytes
  end

  ncqprefix(nsdelta, NANOSECS_IN_SEC, timebuf, 0)
  ncbprefix(totalbytes, 1, totalbuf, 0)
  table_segment(
    n,
    "",
    "══╧════════╧════════╪═══════╪═════════╪═══════╧══╧══╧══╧═══════╝\n",
    "--+--------+--------+-------+---------+-------+--+--+--+-------+\n",
  )
  ncplane_putstr(n, "            ")
  table_printf(n, sep, "%*ss", ncprefixfmt(timebuf), timebuf)
  table_printf(n, sep, "%7lu", totalframes)
  table_printf(n, sep, "%*s", ncbprefixfmt(totalbuf), totalbuf)

  ncplane_putchar(n, '\n')
  ncplane_set_fg_rgb8(n, 0xfe, 0x20, 0x76) # PANTONE Strong Red C + 3x0x20

  unless canimage
    ncplane_putstr(n, "\nNo multimedia support. Some demos are unavailable.\n")
  end

  unless canvideo
    ncplane_putstr(n, "\nNo video support. Some demos are unavailable.\n")
  end

  ncplane_set_fg_rgb8(n, 0xff, 0xb0, 0xb0)

  if failed
    ncplane_printf(
      n,
      "\nError running demo.\nIs \"%s\" the correct data path? Supply it with -p.\n",
      datadir
    )
  end

  failed
end

def scrub_stdplane(nc)
  n = notcurses_stdplane(nc)
  channels = 0
  ncchannels_set_fg_rgb(channels, 0)
  ncchannels_set_bg_rgb(channels, 0)
  return -1 if ncplane_set_base(n, "", 0, channels)
  ncplane_erase(n)
  0
end

def main(argc, argv)
  # This is probably a good approximation of the C code I guess
  unless RUBY_PLATFORM =~ /mingw32/
    trap('WINCH', 'IGNORE') if Signal.list.include?('WINCH')
  end

  spec = String.new
  json_file = nil
  nopts = NotcursesOptions.new

  if (spec = handle_opts(ARGV.size, ARGV, nopts, json))
    usage(File.basename($0), EXIT_FAILURE) unless ARGV.empty?
    spec = DEFAULT_DEMO
  end

  spec_charray = spec.each_char.to_a
  spec_charray.each_with_index do |ch, idx|
    demo_idx = ch.ord - 'a'.ord
    if demo_idx.negative? || demo_idx > 25 || !$demos[demo_idx].name
      $stderr.puts "Invalid demo specification: #{ch}"
      usage(ARGV, EXIT_FAILURE)
    end
  end

  # Not sure why this is there in the original C code... commenting out for
  # now.
  #starttime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  return EXIT_FAILURE unless (nc = notcurses_init(nopts, nil))

  notcurses_mice_enable(nc, NCMICE_BUTTON_EVENT | NCMICE_DRAG_EVENT)
  canimage = notcurses_canopen_images(nc)
  canvideo = notcurses_canopen_videos(nc)
  dimx, dimy = 0, 0
  ncplane_dim_yx(notcurses_stdplane(nc), dimy, dimx)
  raise StandardError unless input_dispatcher(nc).zero?
  raise StandardError if (dimy < MIN_SUPPORTED_ROWS || dimx < MIN_SUPPORTED_COLS)

  if (nopts.flags & NCOPTION_NO_ALTERNATE_SCREEN)
    sleep_time = $demodelay.tv_sec >= 1 ? 1 : $demodelay.tv_sec
    sleep sleep_time
  end

  loop do
    $restart_demos = false
    $interrupted = false

    notcurses_drop_planes(nc)

    raise StandardError unless scrub_stdplane(nc).zero?
    raise StandardError unless hud_create(nc)
    raise StandardError unless fpsgraph_init(nc).zero?
    raise StandardError unless (menu = menu_create(nc))
    raise StandardError unless notcurses_render(nc).zero?

    notcurses_stats_reset(nc, nil)

    raise StandardError unless ext_demos(nc, spec).zero?
    raise StandardError unless hud_destroy.zero?
    raise StandardError unless fpsgraph_stop.zero?

    about_destroy(nc)

    break unless $restart_demos
  end

  ncmenu_destroy(menu)
  stop_input
  notcurses_render(nc)
  r = summary_table(nc, spec, canimage, canvideo)
  notcurses_render(nc)

  raise StandardError unless notcurses_stop(nc).zero?
  raise StandardError unless (json_file && summary_json(json, spec, dimy, dimx))
  raise StandardError unless r.zero?

  return EXIT_SUCCESS
rescue
  stop_input
  notcurses_stop(nc)

  if (dimy < MIN_SUPPORTED_ROWS || dimx < MIN_SUPPORTED_COLS)
    $stderr.printf(
      "At least a %dx%d terminal is required (current: %dx%d)\n",
      MIN_SUPPORTED_ROWS,
      MIN_SUPPORTED_COLS,
      dimy,
      dimx,
    )
  end

  return EXIT_FAILURE
end

main
