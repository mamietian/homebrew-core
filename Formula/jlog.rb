class Jlog < Formula
  desc "Pure C message queue with subscribers and publishers for logs"
  homepage "https://labs.omniti.com/labs/jlog"
  url "https://github.com/omniti-labs/jlog/archive/2.2.1.tar.gz"
  sha256 "bb13258ed1aa490f6325c3f2b72d5fa23c6f4180d7b4691547ccddeec96aae0a"
  head "https://github.com/omniti-labs/jlog.git"

  bottle do
    cellar :any
    sha256 "732114259e80346e3a1ab76153c6a4793b0c947faad0458207a85746b546720d" => :el_capitan
    sha256 "20832b06d6b553bf50ae81faf7e4893d0c6c2f5a6deda84ea520f7cab4a389c7" => :yosemite
    sha256 "df68f1178f440d0ace72c4b78df4f7d9b3740bc71fbeb78d40df3ad9486b8c50" => :mavericks
  end

  depends_on "automake" => :build
  depends_on "autoconf" => :build

  def install
    system "autoconf"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"jlogtest.c").write <<-EOF.undent
      #include <stdio.h>
      #include <jlog.h>
      int main() {
        jlog_ctx *ctx;
        const char *path = "#{testpath}/jlogexample";
        int rv;

        // First, ensure that the jlog is created
        ctx = jlog_new(path);
        if (jlog_ctx_init(ctx) != 0) {
          if(jlog_ctx_err(ctx) != JLOG_ERR_CREATE_EXISTS) {
            fprintf(stderr, "jlog_ctx_init failed: %d %s\\n", jlog_ctx_err(ctx), jlog_ctx_err_string(ctx));
            exit(1);
          }
          // Make sure it knows about our subscriber(s)
          jlog_ctx_add_subscriber(ctx, "one", JLOG_BEGIN);
          jlog_ctx_add_subscriber(ctx, "two", JLOG_BEGIN);
        }

        // Now re-open for writing
        jlog_ctx_close(ctx);
        ctx = jlog_new(path);
        if (jlog_ctx_open_writer(ctx) != 0) {
           fprintf(stderr, "jlog_ctx_open_writer failed: %d %s\\n", jlog_ctx_err(ctx), jlog_ctx_err_string(ctx));
           exit(0);
        }

        // Send in some data
        rv = jlog_ctx_write(ctx, "hello\\n", strlen("hello\\n"));
        if (rv != 0) {
          fprintf(stderr, "jlog_ctx_write_message failed: %d %s\\n", jlog_ctx_err(ctx), jlog_ctx_err_string(ctx));
        }
        jlog_ctx_close(ctx);
      }
    EOF
    system ENV.cc, "jlogtest.c", "-I#{include}", "-ljlog", "-o", "jlogtest"
    system testpath/"jlogtest"
  end
end
