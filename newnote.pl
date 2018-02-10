##########################################################################
#
# 把 CBETA 舊校勘修訂成新的校勘
#
##########################################################################

use utf8;
use Cwd;
use strict;

my $SourcePath = "c:/cbwork/xml-p5a/T/T01";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/xml-p5a-new/T/T01";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "*.xml";		# 要找的檔案類型

my $lb_n;	# 行首頁欄行
my $serial_no = 0;	# 流水號
my $newid;

SearchDir($SourcePath, $OutputPath);

##########################################################################

sub SearchDir
{
	my $ThisDir = shift;		# 新的所在的目錄
	my $ThisOutputDir = shift;	# 新的的輸出目錄
	
	print "find dir <$ThisDir>\n";
	
	if($MakeOutputPath)	# 如果需要建立對應子目錄
	{
		mkdir($ThisOutputDir) unless(-d $ThisOutputDir);
	}
	
	my $myPath = getcwd();		# 目前路徑
	chdir($ThisDir);
	my @files = glob($FilePattern);
	chdir($myPath);				# 回到目前路徑
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);		# 不要 . 與 ..
		my $NewFile = $ThisDir . "/" . $file ;
		my $NewOutputFile = $ThisOutputDir . "/" . $file ;
		if (-f $NewFile)
		{
			SearchFile($NewFile , $NewOutputFile);
		}
	}
	return unless($IsIncludeSubDir);	# 若不搜尋子目錄就離開
	
	opendir (DIR, "$ThisDir");
	my @files = readdir(DIR);
	closedir(DIR);
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);
		my $NewDir = $ThisDir . "/" . $file ;
		my $NewOutputDir = $ThisOutputDir . "/" . $file ; 
		if (-d $NewDir)
		{
			SearchDir($NewDir, $NewOutputDir);
		}
	}	
}

##########################################################################

sub SearchFile
{
	local $_;
	my $file = shift;
	my $outfile = shift;
	
	#### 要做的事

	print $file . "\n";
	
	open IN, "<:utf8", $file;
	open OUT, ">:utf8", $outfile;
	
	while(<IN>)
	{
		$lb_n = "";		# 頁欄行
		if(/^<lb .*?n="(.*?)"/)
		{
			$lb_n = $1;
		}
		$serial_no = 0;	# 流水號
		
		$_ = RunLine($_);

		print OUT $_;
	}
	
	close IN;
	close OUT;
}

sub RunLine
{
	local $_ = shift;
	while(1)
	{
		my $pos1 = 55555;
		my $pos2 = 55555;
		my $pos3 = 55555;

		$serial_no = $serial_no + 1;
		$serial_no = sprintf("%02d", $serial_no);
		$newid = $lb_n . $serial_no;	# 校勘的 id

		if(/^(.*?)<note resp="[^"]*">/)
		{
			$pos1 = length($1);
		}
		if(/^(.*?)(<app>.*?<\/app>)/)
		{
			$pos2 = length($1);
		}
		if(/^(.*?)(<choice cb:resp=".*?">.*?<\/choice>)/)
		{
			$pos3 = length($1);
		}

		if(($pos1 != 55555) && ($pos1 < $pos2) && ($pos1 < $pos3))
		{		
			if($lb_n eq "")
			{
				print "error no <lb> : $_";
				exit;
			}
			$_ = RunLine1($_);	# 處理校勘1
		}
		elsif(($pos2 != 55555) && ($pos2 < $pos1) && ($pos2 < $pos3))
		{
			if($lb_n eq "")
			{
				print "error no <lb> : $_";
				exit;
			}
			$_ = RunLine2($_);	# 處理校勘2	
		}
		elsif(($pos3 != 55555) && ($pos3 < $pos1) && ($pos3 < $pos2))
		{
			if($lb_n eq "")
			{
				print "error no <lb> : $_";
				exit;
			}
			$_ = RunLine3($_);	# 處理校勘3
		}
		else
		{
			last;	# 跳出去了
		}
	}
	
	return $_;
}

# ●CBETA 新增的 note 轉成「新增校註」
# <note resp="xxxx">ＡＢＣＤＥ</note>
# 轉成：
# <note  n="xxxxxxx"  resp="xxxx" type="add">ＡＢＣＤＥ</note>
# 例 : T01n0026.xml
# <lb n="0574a12" ed="T"/>眠、調<note resp="CBETA.grace">查 P055_p0650b10 調＝掉</note>

sub RunLine1
{
	local $_ = shift;

	s/<note resp="([^"]*)">/<note n="$newid" resp="$1" type="add">/;
	
	return $_;
}


# CBETA 新增的 app 加上 note
# <app><lem resp="xxxx" wit="【CBETA】【麗】">Ａ<note type="cf1">xxxx</note></lem><rdg wit="【大】">Ｂ</rdg></app>
# 轉成：
# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】【麗-CB】，Ｂ【大】</note>
# <app n="xxxxxxx"><lem resp="xxxx" wit="【CB】【麗-CB】">Ａ<note type="cf1">xxxx</note></lem><rdg wit="【大】">Ｂ</rdg></app>

# 例 : T01n0026.xml
# <lb n="0424b03" ed="T"/>謂住岸梵志。此七水喻人，我略說也。如上<app><lem resp="CBETA.maha CBETA.say" wit="【CBETA】【麗】">所<note type="cf1">KI17n0648_p1029c06</note><note type="cf2">T01n0026_p0422a13</note></lem><rdg wit="【大】"><space quantity="0"/></rdg></app>

sub RunLine2
{
	local $_ = shift;

	if(/(<app>.*?<\/app>)/)
	{
		s/(<app>.*?<\/app>)/AppAddNote($1)/e;
	}
	return $_;
}

sub AppAddNote
{
	local $_ = shift;

	s/【CBETA】/【CB】/g;
	s/【麗】/【麗-CB】/g;
	s/【磧砂】/【磧砂-CB】/g;
	s/【嘉興】/【嘉興-CB】/g;
	s/【北藏】/【北藏-CB】/g;
	s/【龍】/【龍-CB】/g;

	my $lem = "";
	my $lem_wit = "";
	my $lem_word = "";
	my $rdg = "";
	my $rdg_level = 0;	# rdg 有幾層?
	my @rdg = ();		# 各層 rdg
	my @rdg_wit = ();
	my @rdg_word = ();
	my $note_text = "";	# note 的內容

	if(/(<lem[ >].*?<\/lem>)/)
	{
		$lem = $1;
		if($lem =~ /wit="(.*?)"/)
		{
			$lem_wit = $1;
		}
		$lem_word = $lem;
		$lem_word =~ s/<lem.*?>//;
		$lem_word =~ s/<\/lem>//;
		$lem_word =~ s/<note type="cf.*?<\/note>//g;
	}
	if(/(<rdg[ >].*<\/rdg>)/)
	{
		$rdg = $1;

		# 也許有多層 rdg
		
		while($rdg =~ /(<rdg[ >].*?<\/rdg>)/)
		{
			$rdg =~ s/(<rdg[ >].*?<\/rdg>)//;
			$rdg[$rdg_level] = $1;
			my $tmp = $rdg[$rdg_level];
			if($tmp =~ /wit="(.*?)"/)
			{
				$rdg_wit[$rdg_level] = $1;
			}
			$tmp =~ s/<rdg.*?>//;
			$tmp =~ s/<\/rdg>//;
			$tmp =~ s/<note type="cf.*?<\/note>//g;
			$rdg_word[$rdg_level] = $tmp;
			$rdg_level++;
		}
	}

	# 處理 <note> 標記的文字

	if($lem_word eq "")
	{
		$note_text .= "［－］";
	}
	elsif($lem_word eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $lem_word;
	}
	$note_text .= $lem_wit;

	for(my $i=0; $i<$rdg_level; $i++)
	{
		$note_text .= "，";
		if($rdg_word[$i] eq "")
		{
			$note_text .= "［－］";
		}
		elsif($rdg_word[$i] eq "<space quantity=\"0\"/>")
		{
			$note_text .= "［－］";
		}
		else
		{
			$note_text .= $rdg_word[$i];
		}
		$note_text .= $rdg_wit[$i];
	}

	# 組合最後結果
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】【麗-CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem resp="xxxx" wit="【CB】【麗-CB】">Ａ<note 

	my $out = "<note n=\"" . $newid . "\" resp=\"CBETA\" type=\"add\">";
	$out .= $note_text . "</note>";

	s/<app>/<app n="$newid">/;

	$out .= $_;
	return $out;
}


# ●CBETA 新增的 choice 轉成 note + app
# <choice cb:resp="xxxx"><corr>Ａ</corr><sic>Ｂ</sic></choice>
# 轉成：
# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】，Ｂ【大】</note>
# <app n="xxxxxxx"><lem wit="【CB】" resp="xxxx">Ａ</lem><rdg wit="【大】">Ｂ</rdg></app>

# 例 : T01n0026.xml
# <lb n="0425b21" ed="T"/>絞勒其<anchor xml:id="fxT01p0425b01"/><choice cb:resp="CBETA.maha CBETA.pan"><corr>𨄔</corr><sic>摶</sic></choice>斷皮，斷皮已斷肉，斷肉已斷

sub RunLine3
{
	local $_ = shift;

	if(/(<choice cb:resp=".*?">.*?<\/choice>)/)
	{
		s/(<choice cb:resp=".*?">.*?<\/choice>)/Choice2Note($1)/e;
	}
	return $_;
}

sub Choice2Note
{
	local $_ = shift;

	my $resp = "";
	my $lem = "";
	my $rdg = "";

	my $note_text = "";		# note 的內容

	if(/<choice cb:resp="(.*?)">/)
	{
		$resp = $1;
	}
	if(/<corr>(.*?)<\/corr>/)
	{
		$lem = $1;
	}
	if(/<sic>(.*?)<\/sic>/)
	{
		$rdg = $1;
	}

	# 處理 <note> 標記的文字

	if($lem eq "")
	{
		$note_text .= "［－］";
	}
	elsif($lem eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $lem;
	}
	$note_text .= "【CB】，";

	if($rdg eq "")
	{
		$note_text .= "［－］";
	}
	elsif($rdg eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $rdg;
	}
	$note_text .= "【大】";	

	# 組合最後結果
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem wit="【CB】" resp="xxxx">Ａ</lem><rdg wit="【大】">Ｂ</rdg></app>

	my $out = "<note n=\"" . $newid . "\" resp=\"CBETA\" type=\"add\">";
	$out .= $note_text . "</note>";

	$out .= "<app n=\"$newid\"><lem wit=\"【CB】\" resp=\"$resp\">$lem</lem><rdg wit=\"【大】\">$rdg</rdg></app>";

	return $out;
}



