defmodule JidoCodeCore.Tools.SecurityTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.Tools.Security

  @moduletag :tools
  @moduletag :security

  # Use a temporary directory for all tests
  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "security_test_#{:rand.uniform(1_000_000)}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, project_root: tmp_dir}
  end

  describe "validate_path/3" do
    test "accepts valid relative path", %{project_root: root} do
      assert {:ok, resolved} = Security.validate_path("src/file.ex", root)
      assert String.starts_with?(resolved, root)
    end

    test "accepts valid absolute path within project", %{project_root: root} do
      file_path = Path.join(root, "src/file.ex")
      assert {:ok, ^file_path} = Security.validate_path(file_path, root)
    end

    test "accepts empty string as current directory", %{project_root: root} do
      assert {:ok, ^root} = Security.validate_path("", root)
    end

    test "accepts dot as current directory", %{project_root: root} do
      assert {:ok, ^root} = Security.validate_path(".", root)
    end

    test "accepts nested valid paths", %{project_root: root} do
      assert {:ok, resolved} = Security.validate_path("lib/nested/deep/file.ex", root)
      assert String.starts_with?(resolved, root)
    end

    test "rejects path traversal with double dot", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.validate_path("../../../etc/passwd", root)
    end

    test "rejects path traversal mixed with valid paths", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.validate_path("src/../../../etc/passwd", root)
    end

    test "rejects absolute path outside project", %{project_root: root} do
      assert {:error, :path_outside_boundary} =
               Security.validate_path("/etc/passwd", root)
    end

    test "rejects absolute path similar to project root", %{project_root: root} do
      # Create a path that starts similarly but is different
      similar_root = root <> "_similar"
      assert {:error, :path_outside_boundary} =
               Security.validate_path(Path.join(similar_root, "file.ex"), root)
    end

    test "rejects protected settings file", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.validate_path(".jido_code/settings.json", root)
    end

    test "rejects protected settings file in nested directory", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.validate_path("subdir/.jido_code/settings.json", root)
    end

    test "rejects protected settings file with absolute path", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.validate_path(Path.join(root, ".jido_code/settings.json"), root)
    end

    test "rejects URL-encoded path traversal", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.validate_path("%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd", root)
    end

    test "rejects URL-encoded path traversal variations", %{project_root: root} do
      traversal_patterns = [
        "%2e%2e/",
        "..%2f",
        "%2e%2e\\",
        "..%5c",
        "%2E%2E%2F",
        "%2e%2e%2f"
      ]

      Enum.each(traversal_patterns, fn pattern ->
        path = pattern <> String.duplicate(pattern, 5) <> "etc/passwd"
        assert {:error, :path_escapes_boundary} = Security.validate_path(path, root)
      end)
    end

    test "rejects double URL-encoded traversal", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.validate_path("%252e%252e%252f%252e%252e%252fetc/passwd", root)
    end

    test "returns error for non-binary path", %{project_root: root} do
      assert {:error, :invalid_path} = Security.validate_path(123, root)
      assert {:error, :invalid_path} = Security.validate_path(nil, root)
      assert {:error, :invalid_path} = Security.validate_path(:atom, root)
    end

    test "returns error for non-binary project root" do
      assert {:error, :invalid_path} = Security.validate_path("file.ex", 123)
      assert {:error, :invalid_path} = Security.validate_path("file.ex", nil)
    end

    test "with log_violations: false does not log", %{project_root: root} do
      # This test verifies the option is accepted
      # Actual logging verification would require capturing Logger output
      assert {:error, :path_escapes_boundary} =
               Security.validate_path("../../../etc/passwd", root, log_violations: false)
    end
  end

  describe "within_boundary?/2" do
    test "returns true for path within project root" do
      assert Security.within_boundary?("/project/src/file.ex", "/project")
    end

    test "returns true for project root itself" do
      assert Security.within_boundary?("/project", "/project")
    end

    test "returns true for nested paths" do
      assert Security.within_boundary?("/project/lib/nested/path/file.ex", "/project")
    end

    test "returns false for path outside project root" do
      refute Security.within_boundary?("/etc/passwd", "/project")
    end

    test "returns false for similar but different root" do
      refute Security.within_boundary?("/project2/file.ex", "/project")
    end

    test "returns false for path that prefixes root name" do
      refute Security.within_boundary?("/project_prefixed/file.ex", "/project")
    end

    test "handles trailing slashes correctly" do
      assert Security.within_boundary?("/project/src", "/project/")
      assert Security.within_boundary?("/project/src/", "/project")
    end
  end

  describe "resolve_path/2" do
    test "resolves relative path against project root", %{project_root: root} do
      resolved = Security.resolve_path("src/file.ex", root)
      assert String.starts_with?(resolved, root)
      assert String.ends_with?(resolved, "src/file.ex")
    end

    test "resolves absolute path as-is", %{project_root: root} do
      absolute = Path.join(root, "src/file.ex")
      assert ^absolute = Security.resolve_path(absolute, root)
    end

    test "resolves dot to project root", %{project_root: root} do
      assert ^root = Security.resolve_path(".", root)
    end

    test "resolves double dot within project", %{project_root: root} do
      # Create a test scenario
      nested = Path.join([root, "src", "nested", "file.ex"])
      resolved = Security.resolve_path("../../other.ex", Path.dirname(nested))
      assert String.starts_with?(resolved, root)
    end
  end

  describe "atomic_read/3" do
    setup %{project_root: root} do
      test_file = Path.join(root, "test.txt")
      File.write!(test_file, "test content")

      on_exit(fn ->
        File.rm_rf!(test_file)
      end)

      {:ok, test_file: test_file}
    end

    test "reads valid file successfully", %{test_file: test_file, project_root: root} do
      assert {:ok, "test content"} = Security.atomic_read("test.txt", root)
    end

    test "reads valid file with absolute path", %{
      test_file: test_file,
      project_root: root
    } do
      assert {:ok, "test content"} = Security.atomic_read(test_file, root)
    end

    test "returns error for path outside boundary", %{project_root: root} do
      assert {:error, :path_outside_boundary} =
               Security.atomic_read("/etc/passwd", root)
    end

    test "returns error for path traversal attack", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.atomic_read("../../../etc/passwd", root)
    end

    test "returns error for protected settings file", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.atomic_read(".jido_code/settings.json", root)
    end

    test "returns error for non-existent file", %{project_root: root} do
      assert {:error, :enoent} = Security.atomic_read("nonexistent.txt", root)
    end
  end

  describe "atomic_write/4" do
    test "writes valid file successfully", %{project_root: root} do
      assert :ok = Security.atomic_write("new_file.txt", "content", root)
      assert {:ok, "content"} = File.read(Path.join(root, "new_file.txt"))
    end

    test "creates parent directories if needed", %{project_root: root} do
      assert :ok = Security.atomic_write("nested/deep/file.txt", "content", root)
      assert {:ok, "content"} = File.read(Path.join(root, "nested/deep/file.txt"))
    end

    test "rejects path outside boundary", %{project_root: root} do
      assert {:error, :path_outside_boundary} =
               Security.atomic_write("/etc/evil.txt", "content", root)
    end

    test "rejects path traversal attack", %{project_root: root} do
      assert {:error, :path_escapes_boundary} =
               Security.atomic_write("../../../etc/evil.txt", "content", root)
    end

    test "rejects protected settings file", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.atomic_write(".jido_code/settings.json", "{}", root)
    end

    test "rejects protected settings file in nested path", %{project_root: root} do
      assert {:error, :protected_settings_file} =
               Security.atomic_write("config/.jido_code/settings.json", "{}", root)
    end
  end

  describe "validate_realpath/3" do
    setup %{project_root: root} do
      # Create a test file
      test_file = Path.join(root, "test.txt")
      File.write!(test_file, "content")

      on_exit(fn ->
        File.rm_rf!(test_file)
      end)

      {:ok, test_file: test_file}
    end

    test "returns :ok for file within boundary", %{
      test_file: test_file,
      project_root: root
    } do
      assert :ok = Security.validate_realpath(test_file, root)
    end

    test "returns :ok for non-existent file (may be created)", %{project_root: root} do
      assert :ok = Security.validate_realpath(Path.join(root, "new_file.txt"), root)
    end

    test "returns :ok for symlink pointing to file in boundary", %{
      project_root: root
    } do
      # Create a target file within project
      target = Path.join(root, "target.txt")
      File.write!(target, "content")

      # Create symlink to the target
      symlink = Path.join(root, "link.txt")
      :ok = :file.make_symlink(target, symlink)

      result = Security.validate_realpath(symlink, root)

      # Clean up
      File.rm_rf!(symlink)
      File.rm_rf!(target)

      # The symlink points to a file within boundary, so it's OK
      assert :ok = result
    end
  end

  describe "symlink validation" do
    test "rejects symlink that points to directory outside boundary", %{
      project_root: root
    } do
      # Create a directory outside project
      outside_dir = Path.join(System.tmp_dir!(), "outside_#{:rand.uniform(1000)}")
      File.mkdir_p!(outside_dir)

      # Create an absolute symlink from inside project to outside
      symlink = Path.join(root, "escape")
      :ok = :file.make_symlink(outside_dir, symlink)

      # Validating the symlink itself should detect it escapes
      result = Security.validate_path("escape", root)

      # Clean up
      File.rm_rf!(symlink)
      File.rm_rf!(outside_dir)

      assert {:error, :symlink_escapes_boundary} = result
    end

    test "rejects relative symlink that escapes boundary", %{project_root: root} do
      # Create outside directory
      outside_dir = Path.join(System.tmp_dir!(), "outside_#{:rand.uniform(1000)}")
      File.mkdir_p!(outside_dir)

      # Create a file outside
      outside_file = Path.join(outside_dir, "file.txt")
      File.write!(outside_file, "outside")

      # Create relative symlink pointing to parent of project root
      # First, get parent directory of root
      root_parent = Path.dirname(root)

      # Create symlink that uses .. to escape
      link_name = Path.join(root, "escape_link")
      relative_path = Path.relative_to(outside_dir, root)
      :ok = :file.make_symlink("../" <> relative_path, link_name)

      # This should fail validation
      result = Security.validate_path("escape_link", root)

      # Clean up
      File.rm_rf!(link_name)
      File.rm_rf!(outside_dir)

      # The relative symlink that escapes should be detected
      assert {:error, :symlink_escapes_boundary} = result
    end

    test "accepts symlink within boundary", %{project_root: root} do
      # Create target file
      target = Path.join(root, "target.txt")
      File.write!(target, "content")

      # Create symlink within project
      link = Path.join(root, "link.txt")
      :ok = :file.make_symlink(target, link)

      assert {:ok, resolved} = Security.validate_path("link.txt", root)

      # Clean up
      File.rm_rf!(link)
      File.rm_rf!(target)
    end
  end

  describe "edge cases" do
    test "handles very long paths", %{project_root: root} do
      long_path = Path.join(["src" | List.duplicate("nested", 100)]) <> "/file.ex"
      assert {:ok, resolved} = Security.validate_path(long_path, root)
      assert String.starts_with?(resolved, root)
    end

    test "handles special characters in filename", %{project_root: root} do
      special_names = ["file with spaces.txt", "file-with-dashes.txt", "file_with_underscores.txt"]

      Enum.each(special_names, fn name ->
        assert {:ok, resolved} = Security.validate_path(name, root)
        assert String.starts_with?(resolved, root)
      end)
    end

    test "handles unicode characters", %{project_root: root} do
      unicode_names = ["файл.txt", "文件.txt", "ファイル.txt"]

      Enum.each(unicode_names, fn name ->
        assert {:ok, resolved} = Security.validate_path(name, root)
        assert String.starts_with?(resolved, root)
      end)
    end

    test "handles paths with multiple consecutive slashes", %{project_root: root} do
      assert {:ok, resolved} = Security.validate_path("src//file.ex", root)
      assert String.starts_with?(resolved, root)
    end
  end
end
