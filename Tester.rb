require "gtk2"

class Tester
    def initialize
        # scan the system for hard drives
        findHardDrives

        # now lets build our GUI
        winMain = Gtk::Window.new
        winMain.set_title("Hard Drive Tester")
        winMain.border_width = 5 

        driveTable = Gtk::Table.new(@hardDrives.length + 1, 3) # the +1 row is for the status bar
        driveTable.column_spacings = 5
        driveTable.row_spacings = 5

        @statusBar = Gtk::Statusbar.new
        @statusBarContext =@statusBar.get_context_id("Hard Drive Tester")
        @statusBar.push(@statusBarContext, "Ready")
        driveTable.attach_defaults(@statusBar, 0, 3, @hardDrives.length + 1, @hardDrives.length + 2)


        row = 0;
        @hardDrives.each do |hardDrive|
            hdLabel = Gtk::Label.new(hardDrive)

            qsButton = Gtk::Button.new("Quick Scan")
            fsButton = Gtk::Button.new("Full Scan")

            qsButton.signal_connect("clicked") do
                quickHardDriveTest(hardDrive)
            end

            fsButton.signal_connect("clicked") do
                fullHardDriveTest(hardDrive)
            end

            driveTable.attach_defaults(hdLabel, 0, 1, row, row + 1)
            driveTable.attach_defaults(qsButton, 1, 2, row, row + 1)
            driveTable.attach_defaults(fsButton, 2, 3, row, row + 1)
            row += 1
        end

        winMain.signal_connect('delete_event') do
            false
        end

        winMain.signal_connect('destroy') do
            Gtk.main_quit
        end

        winMain.add(driveTable)
        winMain.show_all
        Gtk.main
    end

    def findHardDrives
        @hardDrives = Array.new
        begin
            # lines look like this
            #   8        0 156290904 sda
            #   8        1  81923436 sda1
            #   8        2    104422 sda2
            hdRegex = Regexp.new(/\s+\d\s+\d\s+\d+\s+([a-zA-Z]+)(?!\d)$/);
            File.open("/proc/partitions", "r") do |partitions|
                while(line = partitions.gets)
                    hdRegex.match(line) do |hdMatch|
                        @hardDrives << "/dev/#{hdMatch[1]}"
                    end
                end
            end
        rescue
            puts "We failed! " + $!
        end
    end

    def fullHardDriveTest(hardDrive)
        @statusBar.pop(@statusBarContext)
        @statusBar.push(@statusBarContext, "Starting full scan on #{hardDrive}")
        system "xterm -fg white -bg black -e vdt --read --wait -r #{hardDrive}  &"
    end

    def quickHardDriveTest(hardDrive)
        @statusBar.pop(@statusBarContext)
        @statusBar.push(@statusBarContext, "Starting quick scan on #{hardDrive}")
        system "smartctl -t short #{hardDrive}"

        Thread.new do
            # for now we are sleeping for a hard-coded 2 minutes
            # in the future we should read the sleep time from smartcl
            sleep(2 * 60)

            while 1
                # now check to see if it's done
                smartStatus = `smartctl -c #{hardDrive}`
                testStatusRegex = Regexp.new(/Self-test execution status:\s+\(\s*(\d+)\)/)
                testStatusMatch = testStatusRegex.match(smartStatus)

                if testStatusMatch
                    if testStatusMatch[1] == "0"
                        @statusBar.pop(@statusBarContext)
                        @statusBar.push(@statusBarContext, "Quick test of #{hardDrive} complete")
                        break
                    else
                        @statusBar.pop(@statusBarContext)
                        @statusBar.push(@statusBarContext, "Quick test of #{hardDrive} still running")
                    end
                else
                    @statusBar.pop(@statusBarContext)
                    @statusBar.push(@statusBarContext, "** Quick test of #{hardDrive} - unknown status!")
                    break
                end

                sleep(10)
            end
        end
    end
end

