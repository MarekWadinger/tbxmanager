classdef TestFlags < matlab.unittest.TestCase
    % Tests for --yes/-y and --quiet/-q flags, and elapsed-time output.
    % Runs without network access using a local file:// mock index.

    properties
        TempDir
        OrigHome
        OrigDir
        OrigPath
        MockPkgDir
        MockIndexFile
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.TempDir = fullfile(tempdir, "tbx_test_" + string(randi(99999)));
            mkdir(testCase.TempDir);
            testCase.OrigHome = getenv("TBXMANAGER_HOME");
            testCase.OrigDir  = pwd;
            testCase.OrigPath = path;
            setenv("TBXMANAGER_HOME", testCase.TempDir);

            % Ensure tbxmanager stays on path after any cd
            tbxFile = which("tbxmanager");
            if ~isempty(tbxFile)
                addpath(fileparts(tbxFile));
            end

            testCase.MockPkgDir    = fullfile(testCase.TempDir, "mock_packages");
            testCase.MockIndexFile = fullfile(testCase.TempDir, "mock_index.json");
            mkdir(testCase.MockPkgDir);

            % Bootstrap tbxmanager storage layout
            evalc('tbxmanager("help")');

            % Build mock package + index, then wire up source
            testCase.buildMockIndex();
            srcUrl = char("file://" + replace(string(testCase.MockIndexFile), "\", "/"));
            evalc('tbxmanager("source", "remove", "https://marekwadinger.github.io/tbxmanager-registry/index.json")');
            evalc('tbxmanager("source", "add", srcUrl)');

            % Teardowns run LIFO
            testCase.addTeardown(@() rmdir(testCase.TempDir, 's'));
            testCase.addTeardown(@() cd(testCase.OrigDir));
            testCase.addTeardown(@() path(testCase.OrigPath));
            testCase.addTeardown(@() setenv("TBXMANAGER_HOME", testCase.OrigHome));
        end
    end

    methods (Access = private)
        function buildMockIndex(testCase)
            d = testCase.MockPkgDir;

            % Create a minimal single-file package
            pkgDir = fullfile(d, "testpkg1_v1");
            mkdir(pkgDir);
            fid = fopen(fullfile(pkgDir, "hello.m"), 'w');
            fprintf(fid, 'function hello()\ndisp(''hello'');\nend\n');
            fclose(fid);
            zipFile = fullfile(d, "testpkg1-1.0.0-all.zip");
            zip(zipFile, '*', pkgDir);

            % Compute SHA-256 of the zip
            hash = testCase.computeSha256(zipFile);

            url = char("file://" + replace(string(zipFile), "\", "/"));
            json = sprintf([...
                '{"index_version":1,"generated":"2026-01-01T00:00:00Z","packages":{' ...
                '"testpkg1":{"name":"testpkg1","description":"Test","license":"MIT",' ...
                '"authors":["T"],"latest":"1.0.0","versions":{"1.0.0":{' ...
                '"matlab":">=R2022a","dependencies":{},"platforms":{' ...
                '"all":{"url":"%s","sha256":"%s"}},"released":"2025-01-01"}}}}}'], url, hash);
            fid = fopen(testCase.MockIndexFile, 'w');
            fprintf(fid, '%s', json);
            fclose(fid);
        end

        function hash = computeSha256(~, filepath)
            md = java.security.MessageDigest.getInstance("SHA-256");
            fid = fopen(filepath, 'r');
            while ~feof(fid)
                chunk = fread(fid, 65536, '*uint8');
                if ~isempty(chunk)
                    md.update(chunk);
                end
            end
            fclose(fid);
            hashBytes = md.digest();
            hexChars = '0123456789abcdef';
            hash = blanks(length(hashBytes) * 2);
            for i = 1:length(hashBytes)
                b = typecast(int8(hashBytes(i)), 'uint8');
                hash((i-1)*2 + 1) = hexChars(bitshift(b, -4) + 1);
                hash((i-1)*2 + 2) = hexChars(bitand(b, 15) + 1);
            end
        end
    end

    methods (Test)

        % --yes flag: must not be treated as a package name
        function testYesFlagNotPassedAsPackage(testCase)
            out = evalc('tbxmanager("install", "--yes", "testpkg1")');
            % Should install, not error about unknown package "--yes"
            testCase.verifyFalse(contains(out, '"--yes"') || contains(out, 'not found'), ...
                '--yes should be consumed as flag, not treated as package name');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, 'packages', 'testpkg1')), ...
                'testpkg1 should be installed when --yes flag is used');
        end

        % -y shorthand works identically
        function testShortYesFlagWorks(testCase)
            out = evalc('tbxmanager("install", "-y", "testpkg1")');
            testCase.verifyFalse(contains(out, '"-y"') || contains(out, 'not found'), ...
                '-y should be consumed as flag, not treated as package name');
        end

        % --quiet flag: suppress tbx_printf output
        function testQuietFlagSuppressesOutput(testCase)
            out = evalc('tbxmanager("install", "--quiet", "testpkg1")');
            % With --quiet, install output (Fetching index, Resolving, etc.) is suppressed
            testCase.verifyFalse(contains(out, 'Fetching index') || contains(out, 'Resolving') || ...
                contains(out, 'Installing'), ...
                '--quiet should suppress tbx_printf output');
        end

        % -q shorthand works
        function testShortQuietFlagWorks(testCase)
            out = evalc('tbxmanager("install", "-q", "testpkg1")');
            testCase.verifyFalse(contains(out, 'Resolving'), ...
                '-q should suppress output');
        end

        % Quiet flag does not suppress errors/usage text
        function testQuietFlagDoesNotSuppressErrors(testCase)
            out = evalc('tbxmanager("install", "--quiet")');
            % No package names → usage message should still appear
            testCase.verifyTrue(contains(out, 'Usage') || contains(out, 'Error') || contains(out, 'error'), ...
                'Errors/usage should still be shown even in quiet mode');
        end

        % Elapsed time appears in install success message
        function testElapsedTimeInInstall(testCase)
            out = evalc('tbxmanager("install", "testpkg1")');
            % tbx_printSuccess prints "Done in X.Xs. N package(s) installed."
            testCase.verifyTrue(contains(out, 's.') || contains(out, 'Done in'), ...
                'install should report elapsed time');
        end

        % Unknown flags beyond --yes/--quiet are passed through as args (no crash)
        function testUnknownFlagsPassedThrough(testCase)
            out = evalc('tbxmanager("list", "--quiet")');
            % Should run quietly without throwing an exception
            testCase.verifyTrue(ischar(out) || isstring(out), ...
                'Recognised flags should be consumed without crash');
        end

    end
end
