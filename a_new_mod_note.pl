##########################################################################
#
# 處理 note/mod , 改成 CBETA 新版的格式  heaven 2018/01/29
# 詳細格式見最底下註解
#
##########################################################################

use utf8;
use Cwd;
use strict;
use XML::DOM;
my $parser = new XML::DOM::Parser;

my $SourcePath = "c:/temp/xml-p5a-new/T/T01";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/xml-p5a-new/TT/T01";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /
my $log_file1 = "a_new_mod_note_log.txt";			# log 檔 , 記錄轉換的校勘
my $log_file2 = "a_new_mod_note_err_log.txt";		# log 檔 , 記錄有問題的校勘
my $log_file3 = "a_new_mod_note_same_log.txt";		# log 檔 , 記錄沒有改變的校勘
my $log_file4 = "a_new_mod_note_mix_log.txt";		# log 檔 , 記錄混合型校勘

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "*.xml";	# 要找的檔案類型

my $lb_num = "";
my $cnum = "[一二三四五六七八九十廿百千]";
my $debug = 0;

my %has_mod_note = ();	# 記錄已經有的 mod id

open LOG1, ">:utf8", $log_file1;
open LOG2, ">:utf8", $log_file2;
open LOG3, ">:utf8", $log_file3;
open LOG4, ">:utf8", $log_file4;
SearchDir($SourcePath, $OutputPath);
close LOG1;
close LOG2;
close LOG3;
close LOG4;

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
	print LOG1 $file . "=============== \n";
	print LOG2 $file . "=============== \n";
	print LOG3 $file . "=============== \n";
	print LOG4 $file . "=============== \n";

	my $text = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	$text .= ParserXML($file);

	open OUT, ">:utf8", $outfile;
	print OUT $text;
	close OUT;
	#exit;
}

##########################################################################
# 處理 XML
sub ParserXML
{
    my $file = shift;
	my $doc = $parser->parsefile($file);
	my $root = $doc->getDocumentElement();

	%has_mod_note = ();	# 記錄已經有的 mod id
	pre_parseNode($root);	# 初步分析, 列出已經有 mod 的 note
	my $text = parseNode($root);	# 全部進行分析
	
	$doc->dispose;
    return $text;
}

# 初步分析, 列出已經有 mod 的 note
sub pre_parseNode
{
    my $node = shift;
    my $nodeTypeName = $node->getNodeTypeName;
	if ($nodeTypeName eq "ELEMENT_NODE") 
    {
        # 處理標記
        my $tag_name = $node->getNodeName();	# 取得標記名稱 

		# 處理標記
        if($tag_name eq "note") { pre_tag_note($node); }
		else { pre_parseChild($node); }				# 處理一般標記
    } 
}

# 處理節點
sub parseNode
{
    my $node = shift;
    my $text = "";
    my $nodeTypeName = $node->getNodeTypeName;
	if ($nodeTypeName eq "ELEMENT_NODE") 
    {
        # 處理標記
        my $tag_name = $node->getNodeName();	# 取得標記名稱 

		# 處理標記
        if($tag_name eq "lb") { $text = tag_lb($node); }
        elsif($tag_name eq "note") { $text = tag_note($node); }
		else { $text = tag_default($node); }				# 處理一般標記
    }
	elsif ($nodeTypeName eq "TEXT_NODE") 
    {
        # 處理文字
        $text = text_handler($node);
    }   
	elsif ($nodeTypeName eq "COMMENT_NODE") 
    {
        # 處理註解
        $text = "<!--" . $node->getNodeValue() . "-->";
    }   
	else
	{
		print $node;
		print "\nFind some data no run !!! Call heaven !!!";
		exit;
	}
    return $text; 
}

# 處理子程序
sub parseChild
{
    my $node = shift;
    my $text = "";
    for my $kid ($node->getChildNodes) 
    {
        $text .= parseNode($kid);
    }
    return $text;    
}


sub pre_parseChild
{
    my $node = shift;
    for my $kid ($node->getChildNodes) 
    {
        pre_parseNode($kid);
    }
}

# 處理文字
sub text_handler
{
    my $node = shift;
    my $text = $node->getNodeValue();   # 取得文字
    #$text =~ s/\n//g;   # 移除換行
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	return $text;     
}

################################
# 處理各種標記
################################

# <lb n="0001a01" ed="T"/>
sub tag_lb
{
    my $node = shift;
	$lb_num = node_get_attr($node,"n");
    return tag_default($node);
}

sub tag_note
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node);   
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);
	
	my $new_child_text = "";
	if($attr_text =~ /type="mod"/)
	{
		$new_child_text = new_mod_note($child_text);	# 處理新式 note mod 內容
	
		if($new_child_text)
		{
			print LOG1 "$lb_num : $text\n";
			
			$text = get_full_tag($tag_name,$attr_text,$new_child_text);
			print LOG1 "$lb_num : $text\n\n";
		}		
		else
		{
			# 沒有變動的 note/mod
			print LOG3 "$lb_num : $text\n";
		}
	}
	elsif($attr_text =~ /type="orig"/)
	{
		if($attr_text =~ /n="(.*?)"/)
		{
			my $n = $1;
			if($has_mod_note{$n} != 1)	# 表示此校勘沒有 mod
			{
				$new_child_text = new_mod_note($child_text);	# 處理新式 note mod 內容
			
				if($new_child_text)
				{
					if($new_child_text ne $text)
					{
						print LOG1 "$lb_num : $text\n";

						my $new_attr_text = $attr_text;
						$new_attr_text =~ s/type="orig"/type="mod"/g;
						$new_attr_text =~ s/resp="Taisho"/resp="CBETA"/g;
						$new_attr_text =~ s/ place="foot text"//;
						$new_child_text = get_full_tag($tag_name,$new_attr_text,$new_child_text);

						print LOG1 "$lb_num : $new_child_text\n\n";
						$text = $text . $new_child_text;
					}
				}		
				else
				{
					# 沒有變動的 note/mod
					print LOG3 "$lb_num : $text\n";
				}
			}
		}
	}

    return $text;
}


sub pre_tag_note
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node);

	if(node_get_attr($node,"type") eq "mod")
	{
		my $n = node_get_attr($node,"n");
		$n =~ s/^(.{7}).*/$1/;
		$has_mod_note{$n} = 1;	# 表示此 id 已經有 mod note 了
	}

    # 處理內容
    pre_parseChild($node);
}

# 處理預設標記
# <tag a="x">abc</tag>
sub tag_default
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node); 
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);
    return $text;
}


# node 取回指定屬性
# 用法 $attr_n = node_get_attr($node,"n");
sub node_get_attr
{
	my $node = shift;
	my $attr = shift;
	my $att_n = $node->getAttributeNode($attr);	# 取得屬性
    if($att_n)
    {
		my $n = $att_n->getValue();	# 取得屬性內容
		$n =~ s/&/&amp;/g;
		$n =~ s/</&lt;/g;
		$n =~ s/&amp;amp;/&amp;/g;
		$n =~ s/&amp;lt;/&lt;/g;
		return $n;
    }
	else
	{
		return "";
	}
}

# 組合成標準標記 <tag a="x">abc</tag>
sub get_full_tag 
{
	my $tag_name = shift;
	my $attr_text = shift;
	my $child_text = shift;
	my $text = "";
	
    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">" . $child_text . "</$tag_name>";
	}
	return $text;
}

# 做出 node 的屬性字串, 如: a="x" b="y" c="z"
sub node_get_attr_text
{
	my $node = shift;
    my $attr_text = "";
	my $attr_map = $node->getAttributes;	# 取出所有屬性
	for my $tag_attr ($attr_map->getValues) # 取出單一屬性
	{
		my $attr_name = $tag_attr->getName;	# 取出單一屬性名稱
		my $attr_value = $tag_attr->getValue;	# 取出單一屬性內容
		$attr_value =~ s/&/&amp;/g;
		$attr_value =~ s/</&lt;/g;
		$attr_value =~ s/&amp;amp;/&amp;/g;
		$attr_value =~ s/&amp;lt;/&lt;/g;
		$attr_text .= " $attr_name=\"$attr_value\"";
	}
	return $attr_text;
}


###########################################################
# 將校勘內容處理成新式的
###########################################################

sub new_mod_note
{
	local $_ = shift;
	my $orig_text = $_;
	my %hash = ();
	my $cbeta_note = "";

	# XXX~xxx 要先處理成XXX【大】，~xxx
	
	if(($_ !~ /，/) && ($_ !~ /【/) && ($_ =~ /^(.*?)(～.*)$/))
	{
		return "$1【大】，$2";
	}

	# 只有一組，沒有版本【】，有巴利用的～符號，傳回原始資料
	#if(($_ !~ /，/) && ($_ !~ /【/) && ($_ =~ /～/))
	# 改成只要沒有 【 就一律使用原始資料
	if($_ !~ /【/)
	{
		return "";
	}

	# 處理單組如下格式
	# 騫茶＝騫荼【宋】＊【元】＊【明】＊～Khaṇḍa.
	if(($_ !~ /，/) && ($_ =~ /^.*?＝.*?【.*?】(?:(?:＊)|(?:下同))?～.*$/))
	{
		$_ = equal_pali($_);
		return $_;
	}
	# 門＋（婆摩婆羅門）【宋】【元】【明】～Vāmaka.
	if(($_ !~ /，/) && ($_ =~ /^.*?＋（.*?）【.*?】(?:(?:＊)|(?:下同))?～.*$/))
	{
		$_ = plus_pali($_);
		return $_;
	}
	# 二作廿二下准之【元】【明】 => 單組，沒有特殊符號，只有版本
	if(($_ !~ /[，＋－＝（）〔〕]/) && ($_ =~ /^.*【.*?】(?:(?:＊)|(?:下同))?$/))
	{
		return "";
	}

	# 如果前面有 <!-- .*? --> 就先取出來
	if(/^<!--.*?-->/)
	{
		s/^(<!--.*?-->)//g;
		$cbeta_note = $1;
	}
	
	# 先將校勘分組
	my @notes = split(/，/,$_);
	my $real_item_num = 0;	# 實際的組數, 若第一組是 ～abc 這就不算一組，要有【版本】才算
	my $taisho_word = "";	# 大正藏版本用字
	my $pure_note = 0;		# 如果有 夾註、XX字、…符號等說明，就不是純文字校註，不可亂置換。

	for(my $i=0; $i<=$#notes; $i++)
	{
		$_ = $notes[$i];
		my $j = 10+$i;	# 文字之前要加上 <$j> 用來排序, 最後再移除
		$_ =~ s/\s*$//;

		if(/【/)
		{
			$real_item_num += 1;	# 真正有版本的組數
		}

		# 類型1 （Ａ）Ｘ字＝Ｂ【Ｘ】=>Ａ【大】，Ｂ【Ｘ】
		if(/^（(.+?)）(${cnum}+?)字＝(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $s4 = $4;
			my $star = "";
			if($s4 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s4 =~ /】下同【/ || $s4 =~ /】下同$/ )
			{
				$star = "下同";
			}

			# 在第一組
			if($real_item_num == 1)
			{
				if(skip_this_num($s1,$2))
				{
					$taisho_word = $s1;
					$hash{$s1} = "【大】$star";
					$hash{"<$j>$s3"} = $s4;
					$notes[$i] = "";

					$pure_note = check_pure_note($taisho_word);
				}
				else
				{
					# 字數不合
					$taisho_word = $s1;
					$hash{"（$s1）${s2}字"} = "【大】$star";
					$hash{"<$j>$s3"} = $s4;
					$notes[$i] = "";

					$pure_note = 0;
				}
			}
			else
			# 也有在第二組的
			#〔東晉…譯〕－【聖】，（東晉…譯）十三字＝符秦建元年三藏曇摩難提譯【宋】【元】
			{
				if($taisho_word eq $s1)
				{
					$hash{"<$j>$s3"} = $s4;
					$notes[$i] = "";
				}
			}
		}
		# 類型1 Ａ＝Ｂ【Ｘ】=>Ａ【大】，Ｂ【Ｘ】
		elsif(/^(.+?)＝(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $star = "";
			if($s3 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
			{
				$star = "下同";
			}

			# 在第一組
			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				$hash{$s1} = "【大】$star";
				$hash{"<$j>$s2"} = $s3;
				$notes[$i] = "";

				$pure_note = check_pure_note($taisho_word);
			}
			# 在第二組之後, 例
			#〔後秦弘始年佛陀耶舍共竺佛念譯〕－【聖】，後秦弘始年＝姚奉三藏法師【宋】【元】【明】
			else
			{
				if($taisho_word =~ /$s1/ && $pure_note)
				{
					my $this_word = $taisho_word;
					$this_word =~ s/$s1/$s2/;
					
					$hash{"<$j>$this_word"} = $s3;
					$notes[$i] = "";
				}
			}
		}
		# 類型2 〔Ａ〕－【Ｘ】=>Ａ【大】，〔－〕【Ｘ】
		elsif(/^〔(.+?)〕－(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $star = "";
			if($s2 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s2 =~ /】下同【/ || $s2 =~ /】下同$/ )
			{
				$star = "下同";
			}
			
			# 在第一組
			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				$hash{$s1} = "【大】$star";
				$hash{"<$j>〔－〕"} = $s2;
				$notes[$i] = "";
				$pure_note = check_pure_note($taisho_word);
			}
			# 在第二組之後, 例
			# 是時＝時為【宋】【元】【明】，〔是〕－【聖】
			else
			{
				if($taisho_word =~ /$s1/ && $pure_note)
				{
					my $this_word = $taisho_word;
					$this_word =~ s/$s1//;
					if($this_word eq "")
					{
						$this_word = "〔－〕";
					}
					$hash{"<$j>$this_word"} = $s2;
					$notes[$i] = "";
				}
				elsif($taisho_word eq $s1)	# 相等的話, 也可以不用 #pure_note
				{
					$hash{"<$j>〔－〕"} = $s2;
					$notes[$i] = "";
				}
			}
		}
		# 類型3 （Ａ）＋Ｂ【Ｘ】=>Ｂ【大】，ＡＢ【Ｘ】
		elsif(/^（(.+?)）＋(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $star = "";
			if($s3 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
			{
				$star = "下同";
			}

			if($real_item_num == 1)
			{
				$taisho_word = $s2;
				$hash{$s2} = "【大】$star";
				$hash{"<$j>$s1$s2"} = $s3;
				$notes[$i] = "";
				$pure_note = check_pure_note($taisho_word);
			}
			else
			{
				if($taisho_word =~ /$s2/ && $pure_note)
				{
					my $this_word = $taisho_word;
					$this_word =~ s/$s2/$s1$s2/;
					
					$hash{"<$j>$this_word"} = $s3;
					$notes[$i] = "";
				}
			}
		}
		# 類型3-1 （Ａ）＋Ｂ【Ｘ】=>Ｂ【大】，ＡＢ【Ｘ】
		elsif(/^（(.+?)）(${cnum}+?)字＋(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $s4 = $4;
			my $star = "";

			# 那個 xx 字的數字與括號中數字符合，才能做下去
			if(skip_this_num($s1, $s2))
			{
				if($s4 =~ /＊/)
				{
					$star = "＊";	# 版本有星號, 所以大正也要有
				}
				elsif($s4 =~ /】下同【/ || $s4 =~ /】下同$/ )
				{
					$star = "下同";
				}

				if($real_item_num == 1)
				{
					$taisho_word = $s3;
					$hash{$s3} = "【大】$star";
					$hash{"<$j>$s1$s3"} = $s4;
					$notes[$i] = "";
					$pure_note = check_pure_note($taisho_word);
				}
				else
				{
					if($taisho_word =~ /$s3/ && $pure_note)
					{
						my $this_word = $taisho_word;
						$this_word =~ s/$s3/$s1$s3/;
						
						$hash{"<$j>$this_word"} = $s4;
						$notes[$i] = "";
					}
				}
			}
		}		
		# 類型4 Ａ＋（Ｂ）【Ｘ】=>Ａ【大】，ＡＢ【Ｘ】
		# Ａ可以不存在
		elsif(/^(.*?)＋（(.+?)）(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $star = "";
			if($s3 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
			{
				$star = "下同";
			}

			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				if($s1 eq "")
				{
					$hash{"〔－〕"} = "【大】$star";
				}
				else
				{
					$hash{$s1} = "【大】$star";
				}

				$hash{"<$j>$s1$s2"} = $s3;
				$notes[$i] = "";
				$pure_note = check_pure_note($taisho_word);
			}
			else
			{
				if($s1 == $taisho_word && $pure_note)
				{
					$hash{"<$j>$s1$s2"} = $s3;
					$notes[$i] = "";
				}
			}
		} 
		# 類型4-1 Ａ＋（Ｂ）xx字【Ｘ】=>Ａ【大】，ＡＢ【Ｘ】
		# Ａ可以不存在
		elsif(/^(.*?)＋（(.+?)）(${cnum}+?)字(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $s4 = $4;

			# 那個 xx 字的數字與括號中數字符合，才能做下去
			if(skip_this_num($s2, $s3))
			{
				my $star = "";
				if($s4 =~ /＊/)
				{
					$star = "＊";	# 版本有星號, 所以大正也要有
				}
				elsif($s4 =~ /】下同【/ || $s4 =~ /】下同$/ )
				{
					$star = "下同";
				}

				if($real_item_num == 1)
				{
					$taisho_word = $s1;
					if($s1 eq "")
					{
						$hash{"〔－〕"} = "【大】$star";
					}
					else
					{
						$hash{$s1} = "【大】$star";
					}

					$hash{"<$j>$s1$s2"} = $s4;
					$notes[$i] = "";
					$pure_note = check_pure_note($taisho_word);
				}
				else
				{
					if($s1 == $taisho_word && $pure_note)
					{
						$hash{"<$j>$s1$s2"} = $s4;
						$notes[$i] = "";
					}
				}
			}
		} 
		# 類型5 〔Ａ…Ｂ〕七字－【Ｘ】=>（Ａ…Ｂ）七字【大】，〔－〕【Ｘ】
		elsif(/^〔(.+?)〕((?:${cnum}+?字)|(?:夾註))－(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $star = "";
			if($s3 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
			{
				$star = "下同";
			}

			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				if($s2 =~ /^(${cnum}+?)字$/)
				{
					# XX字
					my $n = $1;
					if(skip_this_num($taisho_word, $n))	# 字數一定要符合
					{
						#字數相符
						$hash{"$s1"} = "【大】$star";
						$hash{"<$j>〔－〕"} = $s3;
						$notes[$i] = "";
						
						$pure_note = check_pure_note($taisho_word);
					}
					else
					{
						# 字數不符
						$hash{"（$s1）$s2"} = "【大】$star";
						$hash{"<$j>〔－〕"} = $s3;
						$notes[$i] = "";
						$pure_note = 0;
					}
				}
				else
				{
					# 可能是夾註
					
					$hash{"（$s1）$s2"} = "【大】$star";
					$hash{"<$j>〔－〕"} = $s3;
					$notes[$i] = "";
					$pure_note = 0;	
				}
			}
			else
			{
				if($s1 == $taisho_word && $pure_note)
				{
					$hash{"<$j>〔－〕"} = $s3;
					$notes[$i] = "";
				}
				elsif($taisho_word =~ /$s1/ && $pure_note)
				{
					my $this_word = $taisho_word;
					$this_word =~ s/$s1//;
					$hash{"<$j>$this_word"} = $s3;
					$notes[$i] = "";
				}
				elsif($s1 == $taisho_word && $s2 =~ /^(${cnum}+?)字$/)
				{
					# 這也可以取消 〔東晉…譯〕十三字－【聖】
					$hash{"<$j>〔－〕"} = $s3;
					$notes[$i] = "";
				}
			}			
		}
		# 類型6 ＡＢＣ∞ＤＥＦ【Ｘ】=>ＡＢＣ【大】∞ＤＥＦ【Ｘ】
		elsif(/^(.+?)∞(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			my $s1 = $1;
			my $s2 = $2;
			my $s3 = $3;
			my $star = "";
			if($s3 =~ /＊/)
			{
				$star = "＊";	# 版本有星號, 所以大正也要有
			}
			elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
			{
				$star = "下同";
			}

			$notes[$i] = "$s1【大】$star∞$s2$s3";
			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				$pure_note = 0;
			}
		}
		# 後續的文字 ＝ＡＢＣ【Ｘ】
		elsif(/^＝(.+?)(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			if($real_item_num > 1)
			{
				$hash{"<$j>$1"} = $2;
				$notes[$i] = "";
			} 
		}
		# 後續的文字 －【Ｘ】
		elsif(/^－(【.*】(?:(?:＊)|(?:下同))?)$/)
		{
			if($real_item_num > 1)
			{
				$hash{"<$j>〔－〕"} = $1;
				$notes[$i] = "";
			} 
		}
		# 純粹無版本，但後面還有需求。
		# 尼連禪～Hiraññavatī.，＝尼連【宋】【元】【聖】，＝熙連【明】
		# 但最前面不可以無字, 例如 : ～M. 56. Upāli sutta.，婆＝波【聖】＊
		elsif($_ =~ /^.+?～.*$/ && $_ !~ /【/)
		{
			$real_item_num += 1;	# 真正有版本的組數
			$_ =~ /^(.+?)(～.*)$/;

			my $s1 = $1;
			my $s2 = $2;
			
			if($real_item_num == 1)
			{
				$taisho_word = $s1;
				$hash{"$s1"} = "【大】";
				$notes[$i] = "$s2";
				$pure_note = check_pure_note($taisho_word);
			}
		}
	}

	# 把 hash 的資料整理出來

	my $hashdata = hash_to_text(\%hash);
	
	# 再加上那些無法處理的資料

	my $find_special = 0;
	my $find_mix = 0;
	for(my $i=0; $i<=$#notes; $i++)
	{
		if($notes[$i])
		{
			if($notes[$i] =~ /【/)
			{
				if($find_special == 0)
				{
					$hashdata .= "，<!--CBETA todo type: newmod-->" . $notes[$i];
				}
				else
				{
					$hashdata .= "，" . $notes[$i];
				}
				$find_special = 1;	# 有無法處理的資料, 有版本, 麻煩
			}
			else
			{
				$find_mix = 1;	# 有無法處理的資料, 但沒有版本, 無妨
				$hashdata .= "，" . $notes[$i];
			}
		}
	}

	$hashdata =~ s/^，//;

	# 最後加上前面的註解

	$hashdata = $cbeta_note . $hashdata;

	if($find_special)
	{
		print LOG2 "$lb_num : $orig_text\n";
		print LOG2 "$lb_num : $hashdata\n\n";
	}
	elsif($find_mix)
	{
		print LOG4 "$lb_num : $hashdata\n\n";
	}
	return $hashdata;
}

# 處理 hash 的資料變成文字字串
sub hash_to_text
{
	my $hash = shift;
	my $text = "";
	my $cb_text = "";
	my $t_text = "";

	foreach my $key (sort(keys(%$hash)))
	{
		my $origkey = $key;
		$origkey =~ s/^<\d*>//;	# 移除先前為了排序加入的<數字>

		if(%$hash{$key} =~ /【CB】/)
		{
			$cb_text = $origkey . %$hash{$key} . "，";
		}
		elsif(%$hash{$key} =~ /【大】/)
		{
			$t_text = $origkey . %$hash{$key} . "，";
		}
		else
		{
			$text = $text . $origkey . %$hash{$key} . "，";
		}
	}

	if(($text =~ /】(?:＊)/ && $t_text !~ /(?:(?:＊)|(?:下同))/) || ($cb_text =~ /】(?:＊)/ && $t_text !~ /(?:(?:＊)|(?:下同))/))
	{
		# 大正版沒有星號, 其他版卻有星號, 不太合理
		$t_text =~ s/【大】/【大】＊/;
	}
	elsif(($text =~ /】(?:下同)/ && $t_text !~ /(?:(?:＊)|(?:下同))/) || ($cb_text =~ /】(?:下同)/ && $t_text !~ /(?:(?:＊)|(?:下同))/))
	{
		# 大正版沒有下同, 其他版卻有下同, 不太合理
		$t_text =~ s/【大】/【大】下同/;
	}

	my $alltext = $cb_text . $t_text . $text;
	$alltext =~ s/，$//;

	return $alltext;
}

# 處理單組如下格式
# 騫茶＝騫荼【宋】＊【元】＊【明】＊～Khaṇḍa.
sub equal_pali
{
	local $_ = shift;
	my $notetag = "";
	s/^(<!--.*?-->)//;
	$notetag = $1;	# 若有註解, 先取出來
	
	$_ =~ /^(.*?)＝(.*?)(【.*】(?:(?:＊)|(?:下同))?)(～.*)$/;

	my $s1 = $1;
	my $s2 = $2;
	my $s3 = $3;
	my $s4 = $4;

	my $star = "";
	if($s3 =~ /＊/)
	{
		$star = "＊";
	}
	elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
	{
		$star = "下同";
	}

	if($s3 =~ /【CB】/)
	{
		# 有 CB, CB 在前
		$_ = $notetag . $s2 . $s3 . "，" . $s1 . "【大】$star" . "，" . $s4;
	}
	else
	{
		$_ = $notetag . $s1 . "【大】$star" . "，" .  $s2 . $s3 . "，" . $s4;
	}

	return $_;
}

# 處理單組如下格式
# 門＋（婆摩婆羅門）【宋】【元】【明】～Vāmaka.
sub plus_pali
{
	local $_ = shift;
	my $notetag = "";
	s/^(<!--.*?-->)//;
	$notetag = $1;	# 若有註解, 先取出來
	
	$_ =~ /^(.*?)＋（(.*?)）(【.*】(?:(?:＊)|(?:下同))?)(～.*)$/;

	my $s1 = $1;
	my $s2 = $2;
	my $s3 = $3;
	my $s4 = $4;

	my $star = "";
	if($s3 =~ /＊/)
	{
		$star = "＊";
	}
	elsif($s3 =~ /】下同【/ || $s3 =~ /】下同$/ )
	{
		$star = "下同";
	}

	if($s3 =~ /【CB】/)
	{
		# 有 CB, CB 在前
		$_ = $notetag . $1 . $s2 . $s3 . "，" . $s1 . "【大】$star" . "，" . $s4;
	}
	else
	{
		$_ = $notetag . $s1 . "【大】$star" . "，" . $s1 . $s2 . $s3 . "，" . $s4;
	}

	return $_;	
}

# 傳入的字串長度與數字
sub skip_this_num
{
	my $str = shift;
	my $num = shift;

	$str =~ s/<g .*?>/字/g;	# 換成一般的字

	my $strlen = length($str);
	my $numnum = getcnum($num);
	if($strlen == $numnum)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#傳入 百二十三 換成 123
sub getcnum
{
	local $_ = shift;
	my $num = 0;

	# 處理千位
	if(/^(.*)千/)
	{
		s/^(.*)千//;
		my $t = $1;
		if($t eq "")
		{
			$num += 1000;
		}
		else
		{
			$t = getcnum2($t);
			$num = $num + ($t * 1000);
		}
	}

	# 處理百位
	if(/^(.*)百/)
	{
		s/^(.*)百//;
		my $h = $1;
		if($h eq "")
		{
			$num += 100;
		}
		else
		{
			$h = getcnum2($h);
			$num = $num + ($h * 100);
		}
	}

	# 處理十與個位

	if(/^(.)$/)
	{
		my $n = $1;
		$n = getcnum2($n);
		$num += $n;
	}
	elsif(/^十(.)$/)
	{
		my $n = $1;
		$n = getcnum2($n);
		$num = $num + 10 + $n;
	}
	elsif(/^廿(.)$/)
	{
		my $n = $1;
		$n = getcnum2($n);
		$num = $num + 20 + $n;
	}
	elsif(/^(.)十$/)
	{
		my $t = $1;
		$t = getcnum2($t);
		$num = $num + ( 10 * $t );
	}
	elsif(/^(.)十?(.)$/)
	{
		my $t = $1;
		my $n = $2;
		$t = getcnum2($t);
		$n = getcnum2($n);
		$num = $num + ( 10 * $t ) + $n;
	}

	return $num;
}

sub getcnum2
{
	local $_ = shift;

	s/一/1/;
	s/二/2/;
	s/三/3/;
	s/四/4/;
	s/五/5/;
	s/六/6/;
	s/七/7/;
	s/八/8/;
	s/九/9/;
	s/十/10/;
	s/廿/20/;

	return $_;
}

# 檢查是不是純粹的文字校註, 不可以有（）〔〕…這些符號
sub check_pure_note
{
	local $_ = shift;

	if(/[（）〔〕…]/)
	{
		return 0;
	}
	return 1;
}

=begin

要修改的校勘說明

1.Ａ＝Ｂ【Ｘ】=>Ａ【大】，Ｂ【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T01n0001_p0001a19║名。開[7]析修途，所記長遠，故以長為目。翫
    [7] 析＝斤【宋】
    選看「呈現修訂用字」（CBETA 版本）時：
    T01n0001_p0001a19║名。開[7]析修途，所記長遠，故以長為目。翫
    [7] 析【大】，斤【宋】

2.〔Ａ〕－【Ｘ】=>Ａ【大】，〔－〕【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T01n0001_p0001b01║十五年歲次昭陽[10]赤奮若，出此《長阿含》訖。
    [10] 〔赤〕－【宋】【元】
    選看「呈現修訂用字」（CBETA 版本）時：
    T01n0001_p0001b01║十五年歲次昭陽[10]赤奮若，出此《長阿含》訖。
    [10] 赤【大】，〔－〕【宋】【元】
    ps. 這裡以〔－〕表示【宋】【元】本「沒有字」。

3.（Ａ）＋Ｂ【Ｘ】=>Ｂ【大】，ＡＢ【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T01n0001_p0004a20║佛告[7]比丘：「毗婆尸菩薩從兜率天降神母
    [7] （諸）＋比丘【宋】【元】【明】
    選看「呈現修訂用字」（CBETA 版本）時：
    T01n0001_p0004a20║佛告[7]比丘：「毗婆尸菩薩從兜率天降神母
    [7] 比丘【大】，諸比丘【宋】【元】【明】

4.Ａ＋（Ｂ）【Ｘ】=>Ａ【大】，ＡＢ【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T01n0001_p0005b06║[13]一毛生，其毛右旋，紺琉璃色。十二、毛生右
    [13] 一＋（一）【明】
    選看「呈現修訂用字」（CBETA 版本）時：
    T01n0001_p0005b06║[13]一毛生，其毛右旋，紺琉璃色。十二、毛生右
    [13] 一【大】，一一【明】

5.〔Ａ…Ｂ〕七字－【Ｘ】=>（Ａ…Ｂ）七字【大】，〔－〕【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T22n1421_p0005a17║僧伽婆尸沙，[3]不出不淨偷羅遮。　比丘若為
    [3] 〔不出…遮〕七字－【聖】
    選看「呈現修訂用字」（CBETA 版本）時：
    T22n1421_p0005a17║僧伽婆尸沙，[3]不出不淨偷羅遮。　比丘若為
    [3] （不出…遮）七字【大】，〔－〕【聖】
    ps. 這裡以〔－〕表示【聖】本「沒有字」。

6.ＡＢＣ∞ＤＥＦ【Ｘ】=>ＡＢＣ【大】∞ＤＥＦ【Ｘ】

    選看「呈現底本用字」（原書版本）時：
    T22n1425_p0396b14║　無根謗第十，　　[7]迴向遮布薩。
    T22n1425_p0396b15║[8]第九跋渠竟
    [7] 迴向遮布薩∞第九跋渠竟【宮】【聖】
    [8] 迴向遮布薩∞第九跋渠竟【宮】【聖】
    選看「呈現底本用字」（CBETA 版本）時：
    T22n1425_p0396b14║　無根謗第十，　　[7]迴向遮布薩。
    T22n1425_p0396b15║[8]第九跋渠竟
    [7] 迴向遮布薩【大】∞第九跋渠竟【宮】【聖】
    [8] 第九跋渠竟【大】∞迴向遮布薩【宮】【聖】
    ps. 這裡對校註[8]作合理調整。
=end
=cut
