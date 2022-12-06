class Listener < Formula
  desc "A small description of your formula"
  # A home page URL for your software
  homepage "https://github.com/dasmanas/homebrew-rust-app/releases"
  # URL from where the installer archive is available
  url "https://github.com/dasmanas/homebrew-rust-app/releases/download/v0.0.1/rust_app.tar.gz"
  # Sha256 can be calculated using "shasum -a 256 <archive_name.tar.gz>"
  sha256 "c19c678e755d98506c372dd631640702ef2b7da225ffaee20453deb0c2b4a213"
  license "Apache-2.0"
  version "0.0.1"

  def install
    ENV.deparallelize
    # Installing the app
    bin.install "rust_app"
  end

  def post_install
    # Instruction to create a directory which may be used to manage file resources for the app. rust_app directory
    # will be created under /usr/local/var directory.
    (var/"rust_app").mkpath
  end

  # Section to add different instruction for the user
  def caveats
    s = <<~EOS
      We've installed your rust_app.
      To test rust_app installation:
        brew test rust_app
      To run rust_app Node as a background service:
        brew services start rust_app 
      To check the service status:
        brew services list
      To stop rust_app Node background service:
        brew services stop rust_app
    EOS
    s
  end

  service do
    def envvarhash
      return {PATH: std_service_path_env, LISTEN_PORT: "9090"}
    end
    run [opt_bin/"rust_app"]
    keep_alive true
    process_type :background
    environment_variables envvarhash
    log_path var/"rust_app/logs/stdout/rust_app.log"
    error_log_path var/"rust_app/logs/stdout/rust_app.log"
    working_dir var/"rust_app"
  end

  test do
    (testpath/"rust_app").mkpath
    (testpath/"tmp").mkpath
    child_pid = fork do
      puts "Child process initiated to run rust_app"
      puts "Child pid: #{Process.pid}, pgid: #{Process.getpgrp}"
      #setsid() creates a new session if the calling process is not a process group leader.
      Process.setsid
      puts "Child new pgid: #{Process.getpgrp}"
      puts "Initiating rust_app..."
      system "#{bin}/rust_app"
    end
    puts "Waiting for rust_app TCP socket listener to be up..."
    sleep 10
    system "echo sample_text | nc localhost 9090"
    lines = File.open(var/"rust_app/logs/stdout/rust_app.log").to_a
    assert_equal sample_text, lines.last
    pgid = Process.getpgid(child_pid)
    puts "Sending HUP to group #{pgid}..."
    Process.kill('HUP', -pgid)
    Process.detach(pgid)
    puts "Parent process exiting..."
  end

end