# Adjusted from 1.22.0 at homebrew-core
# https://github.com/Homebrew/homebrew-core/blob/173c655e46604b00e75258edab63caaa70e7eedf/Formula/o/onnxruntime.rb
class OnnxruntimeAT1220 < Formula
  desc "Cross-platform, high performance scoring engine for ML models"
  homepage "https://github.com/microsoft/onnxruntime"
  version  "1.22.0"
  url "https://github.com/microsoft/onnxruntime.git",
      revision: "f57db79743c4d1a3553aa05cf95bcd10966030e6" # 1.22.0 plus some fixes
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "python@3.13" => :build

  def install
    python3 = which("python3.13")

    # Use CMake's FetchContent to manage dependencies
    # https://onnxruntime.ai/docs/build/dependencies.html#build-everything-from-source
    cmake_args = %W[
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER
      -Donnxruntime_RUN_ONNX_TESTS=OFF
      -Donnxruntime_GENERATE_TEST_REPORTS=OFF
      -DPYTHON_EXECUTABLE=#{python3}
      -Donnxruntime_BUILD_SHARED_LIB=ON
      -Donnxruntime_BUILD_UNIT_TESTS=OFF
    ]

    system "cmake", "-S", "cmake", "-B", "build", *cmake_args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    
    # Add CoreML provider headers
    cp "include/onnxruntime/core/providers/coreml/coreml_provider_factory.h", "#{include}/onnxruntime/"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <onnxruntime/onnxruntime_c_api.h>
      #include <stdio.h>
      int main()
      {
        printf("%s\\n", OrtGetApiBase()->GetVersionString());
        return 0;
      }
    EOS
    system ENV.cc, "-I#{include}", testpath/"test.c",
           "-L#{lib}", "-lonnxruntime", "-o", testpath/"test"
    assert_equal version, shell_output("./test").strip
  end
end