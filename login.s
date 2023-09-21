* login - sign on
*
* Itagaki Fumihiko 25-Aug-91  Create.
* Itagaki Fumihiko 15-May-92  Set arg0 as -shell[logname]
* 0.5
* Itagaki Fumihiko 25-Dec-94  BSSがきちんと確保されていなかったのを修正
* Itagaki Fumihiko 25-Dec-94  ログイン名入力時, 8文字を超える分はエコーバックしない
* Itagaki Fumihiko 25-Dec-94  ログイン名入力時, ^Hと^?をdelete文字として処理
* Itagaki Fumihiko 25-Dec-94  ログイン名入力時, ^Uは改行しない
* Itagaki Fumihiko 26-Dec-94  ログイン名入力時, ^Wをwerase文字として処理
* Itagaki Fumihiko 26-Dec-94  ログイン名入力時, ^Rをredraw文字として処理
* Itagaki Fumihiko 26-Dec-94  ログイン名入力時, ^Zは通常の文字として処理
* Itagaki Fumihiko 27-Dec-94  パスワード入力時, ^Hと^?をerase文字, ^Wをwerase文字, ^Uをkill文字として処理
* 0.6
*
* Usage: login [ -p ] [ name [ env-var ... ] ]

.include doscall.h
.include chrcode.h
.include limits.h
.include pwd.h

.xref DecodeHUPAIR
.xref minmaxul
.xref iscntrl
.xref isspace2
.xref itoa
.xref utoa
.xref strlen
.xref strchr
.xref strspc
.xref strcmp
.xref stpcpy
.xref strmove
.xref strfor1
.xref strazbot
.xref memcmp
.xref memset
.xref memmovi
.xref skip_space
.xref cat_pathname
.xref headtail
.xref getenv
.xref setenv
.xref getcwd
.xref tfopen
.xref fclose
.xref fgetc
.xref drvchkp
.xref getpass
.xref fgetpwnam
.xref crypt
.xref csleep

** 可変定数
MAXLOGNAME	equ	8
MAXPASSWD	equ	8

STACKSIZE	equ	2048

.text
.even
start:
		bra.s	start1
		dc.b	'#HUPAIR',0			*  HUPAIR適合宣言
.even
start1:
		bra	start2
*****************************************************************
.even

mainjmp:	ds.l	1
mainstack:	ds.l	1
user_envp:	ds.l	1

		ds.b	32
exec_stack_bottom:

shell_pathname:	ds.b	MAXPATH+1

.even
		dc.b	'#HUPAIR',0			*  HUPAIRコマンドライン・マーク
parameter:	ds.b	1+255+1

login_wd:	ds.b	MAXHEAD+1
in_me:		ds.b	1
*****************************************************************
.even
exec:
		DOS	_GETPDB
		movea.l	d0,a0				*  A0 : PDBアドレス
		lea	core_bottom(pc),a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7

		sf	in_me
		DOS	_EXEC
		st	in_me
		lea	14(a7),a7
		tst.l	d0
		bmi	unable_exec
leave:
		move.w	d0,-(a7)
		lea	login_wd(pc),a0
		bsr	chdir
		move.w	(a7)+,d0
do_exit:
		move.w	d0,-(a7)
		DOS	_EXIT2

unable_exec:
		lea	shell_pathname(pc),a0
		lea	msg_unable_to_execute(pc),a1
		bsr	werror2
leave_0:
		moveq	#0,d0
		bra	leave

msg_unable_to_execute:		dc.b	'Unable to execute',0
*****************************************************************
.even
manage_abort_signal:
		move.l	#$3fc,d0		* D0 = 000003FC
		cmp.w	#$100,d1
		bcs	manage_signals

		addq.l	#1,d0			* D0 = 000003FD
		cmp.w	#$200,d1
		bcs	manage_signals

		addq.l	#2,d0			* D0 = 000003FF
		cmp.w	#$ff00,d1
		bcc	manage_signals

		cmp.w	#$f000,d1
		bcc	manage_signals

		move.b	d1,d0
		bra	manage_signals

manage_interrupt_signal:
		move.l	#$200,d0		* D0 = 00000200
manage_signals:
		tst.b	in_me
		beq	do_exit

		move.l	mainstack,a7
		move.l	mainjmp,a0
		jmp	(a0)
****************************************************************
* chdir - change current working directory and/or drive.
*
* CALL
*      A0     string point
*
* RETURN
*      D0.L   DOS status code
*      CCR    TST.L D0
*****************************************************************
chdir:
		move.l	a0,-(a7)
		DOS	_CHDIR
		addq.l	#4,a7
		tst.l	d0
		bmi	chdir_return

		moveq	#0,d0
		move.b	(a0),d0
		cmp.b	#'a',d0
		blo	chdir_1

		cmp.b	#'z',d0
		bhi	chdir_1

		sub.b	#$20,d0
chdir_1:
		sub.b	#'A',d0
		move.w	d0,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		tst.l	d0
chdir_return:
		rts
*****************************************************************
werror2:
		move.l	a0,-(a7)
		movea.l	a1,a0
		bsr	werror
		lea	msg_space_quote(pc),a0
		bsr	werror
		move.l	(a7)+,a0
		bsr	werror
		lea	msg_quote_crlf(pc),a0
werror:
		move.l	a1,-(a7)
		movea.l	a0,a1
werror_count:
		tst.b	(a1)+
		bne	werror_count

		subq.l	#1,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		movea.l	(a7)+,a1
		rts

msg_space_quote:		dc.b	' "',0
msg_quote_crlf:			dc.b	'"',CR,LF,0

.even
core_bottom:
*****************************************************************
start2:
		lea	bsstop(pc),a6			*  A6 := BSSの先頭アドレス
		lea	stack_bottom(a6),a7		*  A7 := スタックの底
		move.l	a3,login_envp(a6)		*  環境のアドレスを記憶する
	*
	*  占有メモリを切り詰める
	*
		DOS	_GETPDB
		movea.l	d0,a0				*  A0 : PDBアドレス
		lea	initial_bottom(pc),a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  login自身のカレント・ディレクトリを保存する
	*
		lea	login_wd(pc),a0
		bsr	getcwd
	*
	*  環境変数 SYSROOT に chdir し，そこをデフォルトのディレクトリとする
	*
		lea	str_nul(pc),a1
		lea	word_SYSROOT(pc),a0
		bsr	getenv
		beq	sysroot_ok

		movea.l	d0,a1
sysroot_ok:
		move.l	a1,sysroot(a6)
		movea.l	a1,a0
		bsr	drvchkp
		bmi	invalid_sysroot

		bsr	chdir
		bmi	invalid_sysroot

		lea	defaultdir(a6),a0
		bsr	getcwd
	*
	*  標準入力が端末かどうかをチェックする
	*
		clr.l	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		lea	msg_not_a_tty(pc),a0
		btst	#7,d0				*  character=1/block=0
		beq	werror_leave_1
	*
	*  引数をデコードし，解釈する
	*
		sf	protect_env(a6)
		clr.b	logname(a6)

		lea	1(a2),a0			*  A0 := コマンドラインの文字列の先頭アドレス
		bsr	strlen				*  D0.L := コマンドラインの文字列の長さ
		addq.l	#1,d0
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		move.l	d0,args(a6)
		movea.l	d0,a1				*  A1 := 引数並び格納エリアの先頭アドレス
		bsr	DecodeHUPAIR			*  引数をデコードする
		movea.l	a1,a0				*  A0 : 引数ポインタ
		move.l	d0,d2				*  D2.L : 引数カウンタ
		beq	parse_arg_done

		lea	str_p(pc),a1
		bsr	strcmp
		bne	no_p

		st	protect_env(a6)
		bsr	strfor1
		subq.l	#1,d2
		beq	parse_arg_done
no_p:
		bsr	strlen
		move.l	#MAXLOGNAME,d1
		bsr	minmaxul
		exg	a0,a1
		lea	logname(a6),a0
		bsr	memmovi
		clr.b	(a0)
		exg	a0,a1
		bsr	strfor1
		subq.l	#1,d2
parse_arg_done:
	*
	*  残りの引数をだけを残して確保メモリを切り詰める
	*
		move.l	d2,argc(a6)
		movea.l	a0,a1
		movea.l	args(a6),a0
		bra	move_envarg_continue

move_envarg_loop:
		bsr	strmove
move_envarg_continue:
		subq.l	#1,d1
		bcc	move_envarg_loop

		move.l	a0,d0
		move.l	args(a6),a0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  シグナル処理ルーチンを設定する
	*
		st	in_me
		lea	leave(pc),a0
		move.l	a0,mainjmp
		lea	exec_stack_bottom(pc),a0
		move.l	a0,mainstack
		pea	manage_interrupt_signal(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
		pea	manage_abort_signal(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
	*
	*  開始
	*
		clr.b	failures(a6)
		bra	check_logname

ask_logname:
	*
	*  ログイン名を入力する
	*
		lea	msg_login(pc),a1
		lea	logname(a6),a0
		moveq	#8,d0
		bsr	getname
check_logname:
	*
	*  ログイン名をチェックする
	*
		lea	logname(a6),a0
		move.b	(a0),d0
		beq	ask_logname

		cmp.b	#'-',d0
		bne	logname_ok

		lea	msg_minus_logname(pc),a0
		bsr	werror
		bra	ask_logname

logname_ok:
	*
	*  パスワード・ファイルを参照する
	*
		lea	file_passwd(pc),a2		*  パスワード・ファイルを
		bsr	open_sysfile			*  オープンする
		bmi	nonexistent_name

		lea	pwd_buf(a6),a0
		lea	pwd_line(a6),a1
		move.l	#PW_LINESIZE,d1
		lea	logname(a6),a2
		bsr	fgetpwnam			*  エントリを得る
		bsr	xfclose
		tst.l	d0
		bne	nonexistent_name

		movea.l	pwd_buf+PW_PASSWD(a6),a0
		tst.b	(a0)				*  パスワードが設定されていなければ
		beq	login_correct			*  ログインを許可する

		cmpi.b	#',',(a0)
		beq	login_correct

		bra	ask_passwd

nonexistent_name:
		lea	salt_xx(pc),a0
		move.l	a0,pwd_buf+PW_PASSWD(a6)
ask_passwd:
	*
	*  パスワードを尋ねて照合する
	*
		lea	msg_password(pc),a1
		lea	password(a6),a0
		move.l	#MAXPASSWD,d0
		bsr	getpass
		movea.l	pwd_buf+PW_PASSWD(a6),a1
		lea	crypt_buf(a6),a2
		bsr	crypt
		bsr	strlen
		move.l	d0,d1
		moveq	#0,d0
		bsr	memset
		bsr	put_newline
		movea.l	a2,a0
		moveq	#13,d0
		bsr	memcmp
		beq	login_correct
	**
	**  ログイン拒否
	**
login_incorrect:
		lea	msg_login_incorrect(pc),a0
		bsr	print
		addq.b	#1,failures(a6)
		cmpi.b	#5,failures(a6)
		blo	ask_logname

		lea	msg_repeated_login_failures(pc),a0
		bsr	werror
		moveq	#1,d0
		bra	sleep_exit
	**
	**  ログイン認可
	**
login_correct:
		tst.l	pwd_buf+PW_UID(a6)		*  uid=0 なら
		beq	do_login			*  無条件にログインする

		bsr	check_nologin
do_login:
	*
	*  ユーザのディレクトリを決定して chdir する
	*
		movea.l	pwd_buf+PW_DIR(a6),a0
		bsr	drvchkp
		bmi	no_dir

		bsr	chdir
		bpl	chdir_ok
no_dir:
		lea	msg_unable_to_change_directory(pc),a1
		bsr	print2
		lea	msg_subst_home(pc),a0
		bsr	print
		lea	defaultdir(a6),a0		*  現在いるディレクトリ（chdir $SYSROOT した結果）を
		move.l	a0,pwd_buf+PW_DIR(a6)		*  ユーザのホーム・ディレクトリとする
		bsr	print
		bsr	put_newline
chdir_ok:
	*
	*  ユーザのシェルとパラメータを決定する
	*
		movea.l	pwd_buf+PW_SHELL(a6),a0
		tst.b	(a0)
		beq	make_default_shell

		movea.l	a0,a1
find_shellname_bottom_loop:
		move.b	(a0)+,d0
		beq	find_shellname_bottom_done

		jsr	isspace2
		bne	find_shellname_bottom_loop
find_shellname_bottom_done:
		subq.l	#1,a0
		move.l	a0,d0
		sub.l	a1,d0
		cmp.l	#MAXPATH,d0
		bhi	too_long_shell

		lea	shell_pathname(pc),a0
		bsr	memmovi
		clr.b	(a0)
		movea.l	a1,a0
		bsr	skip_space
		bra	shell_ok

make_default_shell:
		lea	shell_pathname(pc),a0
		lea	default_shell(pc),a2
		bsr	make_sys_pathname
		bmi	too_long_shell

		lea	default_parameter(pc),a0
shell_ok:
		movea.l	a0,a2				*  A2 : parameter
		bsr	strlen
		move.l	d0,d1				*  D1 : length of parameter
		lea	shell_pathname(pc),a0
		bsr	headtail			*  A1 : basename of shell
		bsr	strlen
		add.l	d1,d0
		move.l	d0,-(a7)
		movea.l	pwd_buf+PW_NAME(a6),a0
		bsr	strlen
		add.l	(a7)+,d0
		cmp.l	#255-5,d0		*  parameter<\0><->shell<[>logname<]><\0>
		bhi	too_long_parameter

		lea	parameter(pc),a0
		exg	a1,a2				*  A1 : parameter
		move.b	d1,(a0)+
		bsr	strmove
		move.b	#'-',(a0)+
		exg	a1,a2				*  A1 : shell
		bsr	stpcpy
		move.b	#'[',(a0)+
		movea.l	pwd_buf+PW_NAME(a6),a1		*  A1 : logname
		bsr	stpcpy
		move.b	#']',(a0)+
		clr.b	(a0)
	*
	*  ユーザの環境を作成する
	*
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		sub.l	#$81000000,d0
		move.l	d0,d1				*  D1.L : 確保可能な大きさ
		cmp.l	#5,d1
		blo	insufficient_memory

		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		move.l	d0,user_envp
		movea.l	d0,a3				*  A3 : ユーザの環境
		movea.l	a3,a2
		move.l	d1,(a2)+
		subq.l	#5,d1
		*
		*  loginの環境を継承する
		*
		movea.l	login_envp(a6),a0
		cmpa.l	#-1,a0
		beq	dupenv_done

		addq.l	#4,a0
dupenv_loop:
		tst.b	(a0)
		beq	dupenv_done

		lea	word_SYSROOT(pc),a1
		bsr	envcmp
		beq	do_dupenv

		tst.b	protect_env(a6)
		beq	dupenv_next

		lea	word_LOGNAME(pc),a1
		bsr	envcmp
		beq	dupenv_next

		lea	word_USER(pc),a1
		bsr	envcmp
		beq	dupenv_next

		lea	word_HOME(pc),a1
		bsr	envcmp
		beq	dupenv_next

		lea	word_SHELL(pc),a1
		bsr	envcmp
		beq	dupenv_next
do_dupenv:
		bsr	strlen
		addq.l	#1,d0
		sub.l	d0,d1
		bcs	insufficient_memory

		movea.l	a0,a1
		movea.l	a2,a0
		bsr	memmovi
		movea.l	a0,a2
		movea.l	a1,a0
		bra	dupenv_loop

dupenv_next:
		bsr	strfor1
		bra	dupenv_loop

dupenv_done:
		clr.b	(a2)
		*
		*  UID, GID, LOGNAME, USER, HOME, SHELL をセットする
		*
		move.l	pwd_buf+PW_UID(a6),d0
		lea	word_UID(pc),a1
		bsr	setenv_num
		bne	insufficient_memory
		*
		move.l	pwd_buf+PW_GID(a6),d0
		lea	word_GID(pc),a1
		bsr	setenv_num
		bne	insufficient_memory
		*
		movea.l	pwd_buf+PW_NAME(a6),a1
		lea	word_LOGNAME(pc),a0
		bsr	setenv
		bne	insufficient_memory
		*
		lea	word_USER(pc),a0
		bsr	setenv
		bne	insufficient_memory
		*
		movea.l	pwd_buf+PW_DIR(a6),a1
		lea	word_HOME(pc),a0
		bsr	setenv
		bne	insufficient_memory
		*
		lea	shell_pathname(pc),a1
		lea	word_SHELL(pc),a0
		bsr	setenv
		bne	insufficient_memory
		*
		*  引数からセットする
		*
		movea.l	args(a6),a0
		move.l	argc(a6),d7
		moveq	#0,d1
		bra	setargenv_continue

setargenv_loop:
		movea.l	a0,a1
		moveq	#'=',d0
		bsr	strchr
		exg	a0,a1
		beq	setargenv_l

		clr.b	(a1)+
		bsr	setenv
		move.b	#'=',-(a1)
		bra	setargenv_doneone

setargenv_l:
		movea.l	a0,a1
		lea	lbuf(a6),a0
		move.b	#'L',(a0)+
		move.l	d1,d0
		addq.l	#1,d1
		bsr	utoa
		subq.l	#1,a0
		bsr	setenv
		movea.l	a1,a0
setargenv_doneone:
		tst.l	d0
		bne	insufficient_memory

		bsr	strfor1
setargenv_continue:
		subq.l	#1,d7
		bcc	setargenv_loop
		*
		*  保存しておいていた引数を解放する
		*
		move.l	args(a6),-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		*
		*  ユーザの環境を切り詰める
		*
		lea	4(a3),a0
		bsr	strazbot
		addq.l	#2,a0
		move.l	a0,d0
		sub.l	a3,d0
		bclr	#0,d0
		move.l	d0,(a3)
		move.l	d0,-(a7)
		move.l	a3,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  $HOME/[.%]hushlogin が無ければ $SYSROOT/etc/motd を出力する
	*
		lea	dot_hushlogin(pc),a0
		bsr	statf
		bpl	motd_done

		lea	percent_hushlogin(pc),a0
		bsr	statf
		bpl	motd_done

		lea	file_motd(pc),a2		*  motd ファイルを
		bsr	open_sysfile			*  オープンしてみる
		bmi	motd_done

		bsr	print_file
motd_done:
	*
	*  ユーザのシェルをexecする
	*
		lea	shell_pathname(pc),a0
		bsr	drvchkp
		bmi	unable_exec

		lea	exec_stack_bottom(pc),a7
		move.l	user_envp(pc),-(a7)		*  ユーザの環境のアドレス
		pea	parameter(pc)			*  起動するプログラムへの引数のアドレス
		move.l	a0,-(a7)			*  起動するプログラムのパス名のアドレス
		clr.w	-(a7)				*  ファンクション：LOAD&EXEC
		bra	exec


too_long_parameter:
		lea	msg_too_long_parameter(pc),a0
		bra	werror_leave_0

too_long_shell:
		lea	msg_too_long_shell(pc),a0
werror_leave_0:
		bsr	werror
		bra	leave_0

invalid_sysroot:
		lea	msg_invalid_sysroot(pc),a1
		bsr	werror2
		bra	leave_1

insufficient_memory:
		lea	msg_insufficient_memory(pc),a0
werror_leave_1:
		bsr	werror
leave_1:
		moveq	#1,d0
		bra	leave
*****************************************************************
setenv_num:
		lea	lbuf(a6),a0
		moveq	#0,d1
		bsr	itoa
		exg	a0,a1
		bra	setenv
*****************************************************************
check_nologin:
		lea	file_nologin(pc),a2
		bsr	open_sysfile
		bmi	check_nologin_return

		bsr	print_file
		moveq	#0,d0
sleep_exit:
		move.l	d0,-(a7)
		move.l	#500,d0
		bsr	csleep
		move.l	(a7)+,d0
		bra	leave

check_nologin_return:
		rts
*****************************************************************
print_file:
		movem.l	d0/a0/a6,-(a7)
		move.l	mainjmp,-(a7)
		move.l	mainstack,-(a7)
		lea	print_file_done(pc),a0
		move.l	a0,mainjmp
		move.l	a7,mainstack
print_file_loop:
		move.w	file_handle(a6),d0
		bsr	fgetc
		bmi	print_file_done

		cmp.b	#LF,d0
		bne	print_file_1char

		bsr	put_newline
		bra	print_file_loop

print_file_1char:
		bsr	putchar
		bra	print_file_loop

print_file_done:
		move.l	(a7)+,mainstack
		move.l	(a7)+,mainjmp
		movem.l	(a7)+,d0/a0/a6
xfclose:
		move.l	d0,-(a7)
		move.w	file_handle(a6),d0
		bsr	fclose
		move.l	(a7)+,d0
		rts
****************************************************************
* getname - 標準入力からエコー付きで1行入力する（CRまたはLFまで）
*
* CALL
*      A0     入力バッファ
*      A1     プロンプト文字列
*      D0.L   最大入力バイト数（CRやLFは含まない）
*
* RETURN
*      D0.L   入力文字数（CRやLFは含まない）
*             ただし EOF なら -1
*      CCR    TST.L D0
****************************************************************
getname:
		movem.l	d1-d3/a0-a2,-(a7)
		move.l	d0,d2
getname_restart:
		exg	a0,a1
		bsr	print
		exg	a0,a1
		moveq	#0,d1				*  D1.L : 入力文字数
		movea.l	a0,a2
getname_loop:
		DOS	_INKEY
		tst.l	d0
		bmi	leave_0

		cmp.b	#$04,d0				*  $04 == ^D
		beq	leave_0

		cmp.b	#CR,d0
		beq	getname_done

		cmp.b	#LF,d0
		beq	getname_done

		cmp.b	#BS,d0
		beq	getname_erase

		cmp.b	#$7f,d0				*  $7f == ^?
		beq	getname_erase

		cmp.b	#$17,d0				*  $17 == ^W
		beq	getname_werase

		cmp.b	#$15,d0				*  $15 == ^U
		beq	getname_kill

		cmp.b	#$03,d0				*  $03 == ^C
		beq	getname_interrupt

		cmp.b	#$12,d0				*  $13 == ^R
		beq	getname_redraw

		cmp.l	d2,d1
		bhs	getname_loop

		bsr	echochar
		move.b	d0,(a2)+
		addq.l	#1,d1
		bra	getname_loop

getname_redraw:
		bsr	put_newline
		move.l	d1,d3
		suba.l	d1,a2
getname_redraw_loop:
		subq.l	#1,d3
		bcs	getname_loop

		move.b	(a2)+,d0
		bsr	echochar
		bra	getname_redraw_loop

getname_erase:
		tst.l	d1
		beq	getname_loop

		bsr	getname_erase_sub
		bra	getname_loop

getname_werase:
		tst.l	d1
		beq	getname_loop

		bsr	getname_erase_sub
		move.b	(a2),d0
		bsr	isspace2
		beq	getname_werase
getname_werase_2:
		tst.l	d1
		beq	getname_loop

		move.b	-1(a2),d0
		bsr	isspace2
		beq	getname_loop
		bsr	getname_erase_sub
		bra	getname_werase_2

getname_kill:
		tst.l	d1
		beq	getname_loop

		bsr	getname_erase_sub
		bra	getname_kill

getname_done:
		bsr	put_newline
		clr.b	(a2)
		move.l	d1,d0
getname_return:
		movem.l	(a7)+,d1-d3/a0-a2
getname_erase_sub_return:
		rts

getname_interrupt:
		bsr	echochar
		move.w	#$200,d0
		bra	leave

getname_erase_sub:
		subq.l	#1,d1
		bsr	put_backspace
		move.b	-(a2),d0
		bsr	iscntrl
		bne	getname_erase_sub_return
put_backspace:
		moveq	#BS,d0
		bsr	putchar
		moveq	#' ',d0
		bsr	putchar
		moveq	#BS,d0
putchar:
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
*****************************************************************
echochar:
		move.w	d0,-(a7)
		move.w	d0,-(a7)
		bsr	iscntrl
		bne	echochar_1

		add.b	#$40,d0
		and.b	#$7f,d0
		move.w	d0,(a7)
		moveq	#'^',d0
		bsr	putchar
echochar_1:
		move.w	(a7)+,d0
		bsr	putchar
		move.w	(a7)+,d0
		rts
*****************************************************************
put_newline:
		move.l	a0,-(a7)
		lea	str_newline(pc),a0
		bsr	print
		movea.l	(a7)+,a0
		rts
*****************************************************************
print2:
		move.l	a0,-(a7)
		movea.l	a1,a0
		bsr	print
		lea	msg_space_quote(pc),a0
		bsr	print
		move.l	(a7)+,a0
		bsr	print
		lea	msg_quote_crlf(pc),a0
print:
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		rts
*****************************************************************
make_sys_pathname:
		movea.l	sysroot(a6),a1
		bra	cat_pathname
*****************************************************************
open_sysfile:
		lea	pathname_buf(a6),a0
		bsr	make_sys_pathname
		bmi	open_file_return

		moveq	#0,d0				*  読み込みモードで
		bsr	tfopen				*  オープンする
		bmi	open_file_return

		move.w	d0,file_handle(a6)
open_file_return:
		rts
*****************************************************************
statf:
		bsr	drvchkp
		bmi	statf_return

		move.w	#$37,-(a7)			*  ボリューム・ラベル以外すべて
		move.l	a0,-(a7)
		pea	statbuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
statf_return:
		rts
*****************************************************************
envcmp:
		move.l	d1,-(a7)
		exg	a0,a1
		bsr	strlen
		exg	a0,a1
		move.l	d0,d1
		bsr	memcmp
		bne	envcmp_return

		move.b	(a0,d1.l),d0
		sub.b	#'=',d0
envcmp_return:
		move.l	(a7)+,d1
		tst.l	d0
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## login 0.6 ##  Copyright(C)1991-94 by Itagaki Fumihiko',0

word_GID:			dc.b	'GID',0
word_HOME:			dc.b	'HOME',0
word_LOGNAME:			dc.b	'LOGNAME',0
word_SHELL:			dc.b	'SHELL',0
word_UID:			dc.b	'UID',0
word_USER:			dc.b	'USER',0
word_SYSROOT:			dc.b	'SYSROOT',0

msg_invalid_sysroot:		dc.b	'login: Invalid $SYSROOT directory',CR,LF,0
msg_not_a_tty:			dc.b	'login: Input is not character device.',CR,LF,0
msg_insufficient_memory:	dc.b	'login: Insufficient memory.',CR,LF,0
msg_login:			dc.b	'login: ',0
msg_password:			dc.b	'Password:',0
msg_minus_logname:		dc.b	"login names may not start with '-'.",CR,LF,0
msg_login_incorrect:		dc.b	'Login incorrect'
str_newline:			dc.b	CR,LF,0
msg_repeated_login_failures:	dc.b	'REPEATED LOGIN FAILURES',CR,LF,0
msg_unable_to_change_directory:	dc.b	'Unable to change directory to',0
msg_subst_home:			dc.b	'Logging in with home=',0
msg_too_long_shell:		dc.b	'Too long shell pathname',CR,LF,0
msg_too_long_parameter:		dc.b	'Too long shell parameter',CR,LF,0

file_passwd:			dc.b	'/etc/passwd',0
file_nologin:			dc.b	'/etc/nologin',0
file_motd:			dc.b	'/etc/motd',0
default_shell:			dc.b	'/bin/COMMAND.X',0
dot_hushlogin:			dc.b	'.hushlogin',0
percent_hushlogin:		dc.b	'%hushlogin',0

salt_xx:			dc.b	'xx',0
str_p:				dc.b	'-p',0
default_parameter:
str_nul:			dc.b	0
*****************************************************************
.bss
.even
bsstop:

.offset 0
sysroot:	ds.l	1
login_envp:	ds.l	1
args:		ds.l	1
argc:		ds.l	1
file_handle:	ds.w	1
pwd_buf:	ds.b	PW_SIZE
pwd_line:	ds.b	PW_LINESIZE
statbuf:	ds.b	53
lbuf:		ds.b	12
crypt_buf:	ds.b	16
failures:	ds.b	1
defaultdir:	ds.b	MAXHEAD+1
logname:	ds.b	MAXLOGNAME+1
password:	ds.b	MAXPASSWD+1
pathname_buf:	ds.b	MAXPATH+1
protect_env:	ds.b	1
.even
		ds.b	STACKSIZE
.even
stack_bottom:

.bss
		ds.b	stack_bottom

initial_bottom:
*****************************************************************

.end start
