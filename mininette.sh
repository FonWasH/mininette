#!/bin/sh

#~ CONFIG ~#
INSTALL=# '/home/user/mininette' '/Volumes/usb_name'
BUILD="$INSTALL/utils/build"
DIFF="$INSTALL/utils/diff"

NORME=# '~/.norminette/norminette.rb' 'norminette'
#https://github.com/42Paris/norminette-v2
#https://github.com/42School/norminette
N_FLAG="" #-R ChecDefine CheckForbiddenSourceHeader
COMP=gcc
C_FLAG='-Wall -Wextra -Werror' #-fsanitize=address -fsanitize=undefined

#~ GLOBAL ~#
EX_PATH=""
EX_NAME=""
EX_CURR=""
EX_FILE=""
EX_TYPE=""
EX_CMD="0"
EX_OK="0"
EX_UK="0"
EX_NB="0"
FAIL="false"
FORCE="false"
NO_TEST="false"
ADD="false"
INDEX="0"
FINAL_GRADE="0"

R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
X='\033[0m'

#~ UTILS ~#
function_title_msg()
{
    cat $INSTALL/docs/title
    echo
}
function_finish_msg()
{
    echo
    if [ "$FINAL_GRADE" -ge "50" ]; then
        echo "Grade : ${G}$FINAL_GRADE${X}/100"
        echo "${G}OK${X} :)"
    else
        echo "Grade : ${R}$FINAL_GRADE${X}/100"
        echo "${R}KO${X} :("
    fi
}
function_test_msg() # (is_last)
{
    total=$((EX_OK+EX_UK))
    value=$((100/EX_NB))
    mod=$((100%EX_NB))
    grade=$((total*value+mod))
    if [ "$grade" -ge "50" ]; then
        echo "$EX_OK / $EX_NB > ${G}success${X}"
    else
        echo "$EX_OK / $EX_NB > ${R}fail${X}"
    fi
    if [ "$1" = "true" ]; then
        if [ "$grade" -lt "$FINAL_GRADE" ]; then
            FINAL_GRADE=$grade
        fi
        function_finish_msg
        function_clean_useless
    else
        FINAL_GRADE=$grade
    fi
}
function_copy() # (from, to)
{
    cp -r $1/* $2 2>> error.log
    if [ $? -ne 0 ]; then
        echo "${R}ERROR${X}: COPY $1"
        exit
    fi
}
function_make_dir() # (dir)
{
    if [ "$FORCE" = "true" ]; then
        rm -rf $1
    fi
    mkdir $1 2>> error.log
    if [ $? -ne 0 ]; then
        echo "${Y}WARNING${X}: ‘$1’ already exist"
        while read -p "do you want to replace it? [Y/y]" answer; do
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                rm -rf $1
                mkdir $1 2>> error.log
                break
            else
                exit
            fi
        done
    fi
}
function_clean_useless()
{
    rm -rf output/ex*/
    rm -f output/*.diff
}
function_update_ex()
{
    EX_CURR=""
    if [ "$INDEX" -lt "10" ]; then
        EX_CURR="ex0$INDEX"
    else
        EX_CURR="ex$INDEX"
    fi
    EX_TYPE=""
    find=$(find $BUILD/$EX_NAME/$EX_CURR -type f -name main.c | wc -l)
    if [ "$find" -gt "0" ]; then
        EX_TYPE="func"
    else
        find=$(find $BUILD/$EX_NAME/$EX_CURR -type f -name 'make-cmd-*.txt' | wc -l)
        if [ "$find" -gt "0" ]; then
            EX_CMD=$find
            EX_TYPE="make"
        else
            find=$(find $BUILD/$EX_NAME/$EX_CURR -type f -name 'prog-cmd-*.txt' | wc -l)
            if [ "$find" -gt "0" ]; then
                EX_CMD=$find
                EX_TYPE="prog"
            else
                EX_TYPE="unavailable"
            fi
        fi
    fi
    EX_FILE="$EX_CURR-$EX_NAME"
}

#~ SYSTEM ~#
function_create_diff_cmd()
{
    i="0"
    test="0"
    function_make_dir $DIFF/$EX_NAME/$EX_CURR
    while [ "$i" != "$EX_CMD" ]; do
        bash $BUILD/$EX_NAME/$EX_CURR/$EX_TYPE-cmd-$i.txt 1> $DIFF/$EX_NAME/$EX_CURR/$EX_FILE-$i.diff 2>> error.log
        if [ $? -ne 0 ]; then
            echo "$EX_CURR > ${R}KO${X}"
        else
            test=$((test+1))
        fi
        i=$((i+1))
    done
    if [ "$test" = "$EX_CMD" ]; then
        echo "$EX_CURR > ${G}OK${X}"
    fi
}
function_create_diff()
{
    function_make_dir $DIFF/$EX_NAME/$EX_CURR
    output/$EX_FILE 1> $DIFF/$EX_NAME/$EX_CURR/$EX_FILE.diff 2>> error.log
    if [ $? -ne 0 ]; then
        echo "$EX_CURR > ${R}KO${X}"
    else
        echo "$EX_CURR > ${G}OK${X}"
    fi
}
function_mininette_cmd()
{
    echo "===== $EX_CURR =====" >> output/trace.txt
    i="0"
    test="0"
    while [ "$i" != "$EX_CMD" ]; do
        bash $BUILD/$EX_NAME/$EX_CURR/$EX_TYPE-cmd-$i.txt 1> output/user-$EX_FILE-$i.diff 2>> error.log
        diff_nb=$(diff -U 3 $DIFF/$EX_NAME/$EX_CURR/$EX_FILE-$i.diff output/user-$EX_FILE-$i.diff | wc -l)
        if [ $diff_nb != "0" ]; then
            diff -U 3 $DIFF/$EX_NAME/$EX_CURR/$EX_FILE-$i.diff output/user-$EX_FILE-$i.diff >> output/trace.txt
            echo "" >> output/trace.txt
            echo "grade :  KO :(" >> output/trace.txt
            FAIL="true"
            echo "$EX_CURR > ${R}KO${X}"
            i=$EX_CMD
        else
            test=$((test+1))
            i=$((i+1))
        fi
    done
    if [ "$test" = "$EX_CMD" ]; then
        if [ $FAIL = "false" ]; then
            EX_OK=$((EX_OK+1))
        fi
        echo "grade : OK :)" >> output/trace.txt
        echo "$EX_CURR > ${G}OK${X}"
    fi
    last=$((EX_NB-1))
    if [ "$INDEX" != "$last" ]; then
        echo "" >> output/trace.txt
    fi
}
function_mininette()
{
    echo "===== $EX_CURR =====" >> output/trace.txt
    output/$EX_FILE 1> output/user-$EX_FILE.diff 2>> error.log
    if [ $? -ne 0 ]; then
        FAIL="true"
        echo "$EX_CURR > ${R}KO${X}"
    else
        diff_nb=$(diff -U 3 $DIFF/$EX_NAME/$EX_CURR/$EX_FILE.diff output/user-$EX_FILE.diff | wc -l)
        if [ $diff_nb = "0" ]; then
            if [ $FAIL = "false" ]; then
                EX_OK=$((EX_OK+1))
            fi
            echo "grade : OK :)" >> output/trace.txt
            echo "$EX_CURR > ${G}OK${X}"
        else
            diff -U 3 $DIFF/$EX_NAME/$EX_CURR/$EX_FILE.diff output/user-$EX_FILE.diff >> output/trace.txt
            echo "" >> output/trace.txt
            echo "grade :  KO :(" >> output/trace.txt
            FAIL="true"
            echo "$EX_CURR > ${R}KO${X}"
        fi
        last=$((EX_NB-1))
        if [ "$INDEX" != "$last" ]; then
            echo "" >> output/trace.txt
        fi
    fi
}
function_make()
{
    cd output/$EX_CURR
    make all >> ../../error.log 2>&1
    make clean >> ../../error.log 2>&1
    prog=$(find . -type f \( -name "ft_*" ! -iname "ft_*.*" \) | tr -d './')
    cd ../..
    mv output/$EX_CURR/$prog output/$prog 2>> error.log
    if [ $? -ne 0 ]; then
        FAIL="true"
        echo "$EX_CURR > ${R}KO${X}"
    else
        if [ "$NO_TEST" = "true" ]; then
            echo "$EX_CURR > ${G}OK${X}"
        elif [ "$ADD" = "true" ]; then
            function_create_diff_cmd
        else
            function_mininette_cmd
        fi
    fi 
}
function_compile()
{
    $COMP $C_FLAG output/$EX_CURR/*.c 2>> error.log
    if [ $? -ne 0 ]; then
        FAIL="true"
        echo "$EX_CURR > ${R}KO${X}"
    else
        mv *.out output/$EX_FILE
        if [ "$NO_TEST" = "true" ]; then
            echo "$EX_CURR > ${G}OK${X}"
        else
            if [ "$EX_TYPE" = "func" ]; then
                if [ "$ADD" = "true" ]; then
                    function_create_diff $EX_FILE
                else
                    function_mininette $EX_FILE
                fi
            elif [ "$EX_TYPE" = "prog" ]; then
                if [ "$ADD" = "true" ]; then
                    function_create_diff_cmd $EX_FILE
                else
                    function_mininette_cmd $EX_FILE
                fi
            fi    
        fi
    fi
}
function_save_src_code()
{
    if [ "$NO_TEST" = "false" ] && [ "$ADD" = "false" ]; then
        echo "===== $EX_CURR =====" >> output/src.txt
        cat output/$EX_CURR/* 1>> output/src.txt 2>> error.log
        echo >> output/src.txt
        cat output/$EX_CURR/*/* 1>> output/src.txt 2>> /dev/null
        cat output/$EX_CURR/*/*/* 1>> output/src.txt 2>> /dev/null
        echo >> output/src.txt
    fi
}
function_compile_msg()
{
    echo
    if [ "$NO_TEST" = "true" ]; then
        echo "--- Compilation ---"
    elif [ "$ADD" = "true" ]; then
        echo "--- Create diff ---"
        mkdir $DIFF 2>> /dev/null
        function_make_dir $DIFF/$EX_NAME
    else
        echo "--- Compilation / Mininette ---"
        function_title_msg >> output/trace.txt
        echo "" >> output/trace.txt
    fi
}
function_check_compile_ex()
{
    INDEX="0"
    EX_OK="0"
    FAIL="false"
    function_compile_msg
    while [ "$INDEX" != "$EX_NB" ]; do
        function_update_ex
        function_save_src_code
        if [ "$EX_TYPE" = "func" ] || [ "$EX_TYPE" = "prog" ]; then
            function_copy $BUILD/$EX_NAME/$EX_CURR output/$EX_CURR
            function_compile
        elif [ "$EX_TYPE" = "make" ]; then
            function_copy $BUILD/$EX_NAME/$EX_CURR/test_file output/$EX_CURR
            function_make
        elif [ "$EX_TYPE" = "unavailable" ]; then
            if [ $FAIL = "false" ]; then
                EX_UK=$((EX_UK+1))
            fi
            echo "$EX_CURR > ${Y}unavailable${X}"
            if [ "$NO_TEST" = "false" ] && [ "$ADD" = "false" ]; then
                echo "===== $EX_CURR =====" >> output/trace.txt
                echo "grade : unavailable" >> output/trace.txt
                echo "" >> output/trace.txt
            fi
        fi
        INDEX=$((INDEX+1))
    done
    if [ "$NO_TEST" = "false" ] && [ "$ADD" = "false" ]; then
        function_test_msg "true"
    elif [ "$ADD" = "true" ]; then
        rm -rf "output"
    fi
}
function_norminette()
{
    echo
    echo "--- Norminette ---"
    INDEX="0"
    EX_OK="0"
    FAIL="false"
    while [ "$INDEX" != "$EX_NB" ]; do
        function_update_ex
        error=$($NORME $N_FLAG output/$EX_CURR/* | grep Error | wc -l)
        if [ $error = "0" ]; then
            if [ $FAIL = "false" ]; then
                EX_OK=$((EX_OK+1))
            fi
            echo "$EX_CURR > ${G}OK${X}"
        else
            FAIL="true"
            echo "$EX_CURR > ${R}KO${X}"
        fi
        INDEX=$((INDEX+1))
    done
    function_test_msg "false"
}
function_start() # (path, name)
{
    function_title_msg
    echo "path      = $1"
    echo "exercice  = $2"
    EX_PATH=$1
    EX_NAME=$2
    function_make_dir "output"
    EX_NB=$(ls $BUILD/$EX_NAME | wc -l)
    function_copy $EX_PATH output
    if [ "$NO_TEST" = "false" ] && [ "$ADD" = "false" ]; then
        function_norminette
    fi
    function_check_compile_ex
}

#~ MAIN ~#
function_help_msg()
{
    if [ "$1" = "--show" ]; then
        function_title_msg
        available=$(ls $DIFF)
        if [ -z "$available" ]; then
            available="null"
        fi
        echo "Available tests"
        echo "${Y}$available${X}"
    elif [ "$1" = "--help" ]; then
        cat $INSTALL/docs/doc | less
    fi
}
function_check_arg()
{
    if [ -z "$1" ]; then
        echo "mininette: argument is missing -- path"
        echo "Try 'mininette --help' for more information."
        exit
    elif [ -z "$2" ]; then
        echo "mininette: argument is missing -- exercise name"
        echo "Try 'mininette --help' for more information."
        exit
    fi
    function_start $1 $2
}
function_check_opt()
{
    find="false"
    opt="f"
    if [ -z "${1##*$opt*}" ] ;then
        FORCE="true"
        find="true"
    fi
    opt="c"
    if [ -z "${1##*$opt*}" ] ;then
        NO_TEST="true"
        find="true"
    fi
    if [ "$find" = "false" ]; then
        echo "mininette: invalid option -- $1"
        echo "Try 'mininette help' for more information."
        exit
    fi
}
main()
{
    opt="-"
    rm -f error.log
    if [ "$1" = "--help" ] || [ "$1" = "--show" ]; then
        function_help_msg $1
    elif [ "$1" = "--clean" ]; then
        rm -rf "output"
        rm -f error.log
    elif [ "$1" = "--add" ]; then
        ADD="true"
        function_check_arg $2 $3
    elif [ -z "${1##*$opt*}" ] ;then
        opt=$(echo $1 | tr -d '-')
        function_check_opt $opt
        function_check_arg $2 $3
    else
        function_check_arg $1 $2
    fi
}

main $1 $2 $3