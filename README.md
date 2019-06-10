# td
Interactive script to take thread dumps.

Make sure that you do a ps -aef | grep java and identify the pid for which you need the thread dump. 
This command will provide you most information you will require to get thread dumps via script.

The script now provides you the option to use force to take threadumps of hung JVM processes.
Below are the two options and their funtions.

l - This option is used for taking threadump normally and this is the preferred way.
F- this option is used to take the threaddump by force and should be used only if the JVM process is in hung state.
