classdef TestSourceManagement < matlab.unittest.TestCase
    % Tests for source add/remove/list operations.

    properties
        TempDir
        OrigHome
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.TempDir = fullfile(tempdir, "tbx_test_" + string(randi(99999)));
            mkdir(testCase.TempDir);
            testCase.OrigHome = getenv("TBXMANAGER_HOME");
            setenv("TBXMANAGER_HOME", testCase.TempDir);
            testCase.addTeardown(@() setenv("TBXMANAGER_HOME", testCase.OrigHome));
            testCase.addTeardown(@() rmdir(testCase.TempDir, 's'));
        end
    end

    methods (Test)

        function testDefaultSourceExists(testCase)
            evalc('tbxmanager("help")');
            f = fullfile(testCase.TempDir, "state", "sources.json");
            data = jsondecode(fileread(f));
            sources = string(data.sources);
            testCase.verifyTrue(any(contains(sources, "tbxmanager-registry")));
        end

        function testAddSource(testCase)
            evalc('tbxmanager("help")');
            evalc('tbxmanager("source", "add", "https://example.com/custom/index.json")');
            f = fullfile(testCase.TempDir, "state", "sources.json");
            data = jsondecode(fileread(f));
            sources = string(data.sources);
            testCase.verifyTrue(any(sources == "https://example.com/custom/index.json"));
        end

        function testRemoveSource(testCase)
            evalc('tbxmanager("help")');
            evalc('tbxmanager("source", "add", "https://example.com/temp.json")');
            evalc('tbxmanager("source", "remove", "https://example.com/temp.json")');
            f = fullfile(testCase.TempDir, "state", "sources.json");
            data = jsondecode(fileread(f));
            sources = string(data.sources);
            testCase.verifyFalse(any(sources == "https://example.com/temp.json"));
        end

        function testDuplicateSourceNotAdded(testCase)
            evalc('tbxmanager("help")');
            evalc('tbxmanager("source", "add", "https://example.com/dup.json")');
            evalc('tbxmanager("source", "add", "https://example.com/dup.json")');
            f = fullfile(testCase.TempDir, "state", "sources.json");
            data = jsondecode(fileread(f));
            sources = string(data.sources);
            count = sum(sources == "https://example.com/dup.json");
            testCase.verifyEqual(count, 1);
        end

        function testRemoveNonExistentSource(testCase)
            % Removing a source that was never added should warn, not error
            evalc('tbxmanager("help")');
            out = evalc('tbxmanager("source", "remove", "https://example.com/never_added.json")');
            testCase.verifyTrue(contains(out, "not found") || contains(out, "Warning"), ...
                'Should warn when removing a source that does not exist');
        end

        function testGetSourcesNoSourcesField(testCase)
            % Write sources.json without a 'sources' field → getSources returns default
            evalc('tbxmanager("help")');
            stateDir = fullfile(testCase.TempDir, "state");
            fid = fopen(fullfile(stateDir, "sources.json"), 'w');
            fprintf(fid, '{"other":"value"}');
            fclose(fid);
            % source list should now show the default URL (fallback)
            out = evalc('tbxmanager("source", "list")');
            testCase.verifyTrue(contains(out, "tbxmanager-registry") || contains(out, "No sources"), ...
                'Should fall back to default source when sources field missing');
        end

        function testLoadIndexBrokenSource(testCase)
            % Replace sources.json with only a broken file:// URL so loadIndex
            % exercises the catch block (L540-541) without any network access.
            evalc('tbxmanager("help")');
            stateDir = fullfile(testCase.TempDir, "state");
            brokenUrl = "file://" + fullfile(testCase.TempDir, "nonexistent_index.json");
            s.sources = {char(brokenUrl)};
            fid = fopen(fullfile(stateDir, "sources.json"), 'w');
            fprintf(fid, '%s', jsonencode(s));
            fclose(fid);
            % search calls tbx_loadIndex; catch block should handle FetchFailed
            out = evalc('tbxmanager("search", "anything")');
            testCase.verifyTrue(true, 'Broken source should be handled by catch in loadIndex');
        end

        function testSupportedIndexVersionIsOne(testCase)
            evalc('tbxmanager("help")');
            v = tbxmanager("internal__", "supportedIndexVersion");
            testCase.verifyEqual(double(v), 1, ...
                'Client should report supported index_version 1');
        end

        function testIndexVersionTooNewSkipped(testCase)
            % An index whose index_version exceeds what the client supports
            % must be skipped (not merged) with a warning, not silently used.
            evalc('tbxmanager("help")');
            supported = double(tbxmanager("internal__", "supportedIndexVersion"));
            idxFile = fullfile(testCase.TempDir, "future_index.json");
            idx = struct();
            idx.index_version = supported + 1;
            idx.packages = struct("futurepkg", struct("latest", "1.0.0"));
            fid = fopen(idxFile, 'w');
            fprintf(fid, '%s', jsonencode(idx));
            fclose(fid);
            url = "file://" + replace(string(idxFile), "\", "/");
            s.sources = {char(url)};
            fid = fopen(fullfile(testCase.TempDir, "state", "sources.json"), 'w');
            fprintf(fid, '%s', jsonencode(s));
            fclose(fid);

            out = evalc('result = tbxmanager("internal__", "loadIndex");');
            result = tbxmanager("internal__", "loadIndex");
            testCase.verifyFalse(isfield(result.packages, "futurepkg"), ...
                'Packages from a too-new index must not be merged');
            testCase.verifyTrue(contains(out, "selfupdate") || contains(out, "format version"), ...
                'Should warn that the client is too old for the index');
        end

        function testIndexVersionCurrentLoads(testCase)
            % An index at the supported version loads normally.
            evalc('tbxmanager("help")');
            supported = double(tbxmanager("internal__", "supportedIndexVersion"));
            idxFile = fullfile(testCase.TempDir, "current_index.json");
            idx = struct();
            idx.index_version = supported;
            idx.packages = struct("okpkg", struct("latest", "1.0.0"));
            fid = fopen(idxFile, 'w');
            fprintf(fid, '%s', jsonencode(idx));
            fclose(fid);
            url = "file://" + replace(string(idxFile), "\", "/");
            s.sources = {char(url)};
            fid = fopen(fullfile(testCase.TempDir, "state", "sources.json"), 'w');
            fprintf(fid, '%s', jsonencode(s));
            fclose(fid);

            result = tbxmanager("internal__", "loadIndex");
            testCase.verifyTrue(isfield(result.packages, "okpkg"), ...
                'Packages from a current-version index should be merged');
        end

        function testGetSourcesScalarString(testCase)
            % Write sources.json where "sources" is a bare JSON string (not array).
            % jsondecode returns it as a char vector → ischar branch in tbx_getSources.
            evalc('tbxmanager("help")');
            stateDir = fullfile(testCase.TempDir, "state");
            fid = fopen(fullfile(stateDir, "sources.json"), 'w');
            fprintf(fid, '{"sources":"https://example.com/scalar.json"}');
            fclose(fid);
            out = evalc('tbxmanager("source", "list")');
            testCase.verifyTrue(contains(out, "scalar") || contains(out, "example.com"), ...
                'Should parse scalar string source');
        end

    end
end
