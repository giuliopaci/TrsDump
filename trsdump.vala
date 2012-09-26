/* valac --pkg libarchive --pkg libxml-2.0 --save-temps */

/***
 * This software is released according to the Expat license below.
 *
 * Copyright: 2012, Giulio Paci <giulio.paci@pd.istc.cnr.it>
 *            2010-2012, Giulio Paci <giuliopaci@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ***/

using Xml;
using Archive;
using Posix;

namespace Trs
{
	public enum TurnTokenType
	{
		SYNC,
			EVENT,
			TEXT,
			UNKNOWN;

		public static TurnTokenType from_string(string name)
		{
			switch(name)
			{
			case "Sync":
				return TurnTokenType.SYNC;
			case "Event":
				return TurnTokenType.EVENT;
			case "Text":
				return TurnTokenType.TEXT;
			default:
				return TurnTokenType.UNKNOWN;
			}
		}

		public string to_string()
		{
			switch(this)
			{
			case TurnTokenType.TEXT:
				return "Text";
			case TurnTokenType.SYNC:
				return "Sync";
			case TurnTokenType.EVENT:
				return "Event";
			default:
				return "";
			}
		}
	}
	public enum SectionType
	{
		REPORT,
			UNKNOWN;

		public static SectionType from_string(string name)
		{
			switch(name)
			{
			case "report":
				return SectionType.REPORT;
			default:
				return SectionType.UNKNOWN;
			}
		}

		public string to_string()
		{
			switch(this)
			{
			case SectionType.REPORT:
				return "report";
			default:
				return "";
			}
		}
	}

	public enum EventType
	{
		NOISE,
			ENTITIES,
			UNKNOWN;

		public static EventType from_string(string name)
		{
			switch(name)
			{
			case "noise":
				return EventType.NOISE;
			case "entities":
				return EventType.ENTITIES;
			default:
				return EventType.UNKNOWN;
			}
		}

		public string to_string()
		{
			switch(this)
			{
			case EventType.NOISE:
				return "noise";
			case EventType.ENTITIES:
				return "entities";
			default:
				return "";
			}
		}
	}

	public enum ExtentType
	{
		BEGIN,
			END,
			INSTANTANEOUS,
			UNKNOWN;

		public static ExtentType from_string(string name)
		{
			switch(name)
			{
			case "begin":
				return ExtentType.BEGIN;
			case "end":
				return ExtentType.END;
			case "instantaneous":
				return ExtentType.INSTANTANEOUS;
			default:
				return ExtentType.UNKNOWN;
			}
		}

		public string to_string()
		{
			switch(this)
			{
			case ExtentType.BEGIN:
				return "begin";
			case ExtentType.END:
				return "end";
			case ExtentType.INSTANTANEOUS:
				return "instantaneous";
			default:
				return "";
			}
		}
	}

	public struct Transcription
	{
		public string scribe;
		public string audio_filename;
		public string version;
		public string version_date;
		public Episode[] episodes;

		public static int parse(TextReader reader, out Transcription transcription)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			string name = reader.name();
			transcription = Transcription(){ scribe = "", audio_filename = "", version = "", version_date = "", episodes = {} };
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				case "scribe":
					transcription.scribe = reader.const_value();
					break;
				case "audio_filename":
					transcription.audio_filename = reader.const_value();
					break;
				case "version":
					transcription.version = reader.const_value();
					break;
				case "version_date":
					transcription.version_date = reader.const_value();
					break;
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							case "Episode":
								transcription.episodes.resize(transcription.episodes.length+1);
								Episode.parse(reader, out transcription.episodes[transcription.episodes.length-1]);
								break;
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}

	public struct Episode
	{
		public Section[] sections;

		public static int parse(TextReader reader, out Episode episode)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			//string name = reader.name();
			ParserUtils.parse_unsupported_attributes(reader);
			episode = Episode() { sections = {} };
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							case "Section":
								episode.sections.resize(episode.sections.length+1);
								Section.parse(reader, out episode.sections[episode.sections.length-1]);
								break;
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}

	public struct Section
	{
		public double start_time;
		public double end_time;
		public SectionType type;
		public Turn[] turns;

		public static int parse(TextReader reader, out Section section)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			string name = reader.name();
			section = Section(){ start_time = -1, end_time = -1, type = SectionType.UNKNOWN, turns = {} };
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				case "type":
					section.type = SectionType.from_string(reader.const_value());
					break;
				case "startTime":
					section.start_time = double.parse(reader.const_value());
					break;
				case "endTime":
					section.end_time = double.parse(reader.const_value());
					break;
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							case "Turn":
								section.turns.resize(section.turns.length+1);
								Turn.parse(reader, out section.turns[section.turns.length-1]);
								break;
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}

	public struct TurnToken
	{
		public TurnTokenType type;
		public Sync sync;
		public string text;
		public Event event;
	}

	public struct Turn
	{
		public double start_time;
		public double end_time;
		public TurnToken[] tokens;

		public static int parse(TextReader reader, out Turn turn)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			string name = reader.name();
			turn = Turn(){ start_time = -1, end_time = -1, tokens = {} };
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				case "startTime":
					turn.start_time = double.parse(reader.const_value());
					break;
				case "endTime":
					turn.end_time = double.parse(reader.const_value());
					break;
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							case "Sync":
								Sync sync;
								Sync.parse(reader, out sync);
								//Posix.stderr.printf("<Sync>\t%f\n", sync.time);
								turn.tokens.resize(turn.tokens.length+1);
								turn.tokens[turn.tokens.length-1] =  TurnToken() {type = TurnTokenType.SYNC, sync = sync};
								break;
							case "Event":
								Event event;
								Event.parse(reader, out event);
								//Posix.stderr.printf("<Event>\t%s\t%s\t%s\n", event.description, event.extent.to_string(), event.type.to_string());
								turn.tokens.resize(turn.tokens.length+1);
								turn.tokens[turn.tokens.length-1] = TurnToken() {type = TurnTokenType.EVENT, event = event};
								break;
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.WHITESPACE:
					case ReaderType.SIGNIFICANT_WHITESPACE:
					case ReaderType.TEXT:
						try {
							var regex = new Regex ("^[[:space:]]+|[[:space:]]+$", RegexCompileFlags.MULTILINE);
							string text = regex.replace (reader.const_value(), -1, 0, "");
							if( ! ( text == "" ) )
							{
								//Posix.stderr.printf("<Text>\t%s\n", text);
								turn.tokens.resize(turn.tokens.length+1);
								turn.tokens[turn.tokens.length-1] = TurnToken() {type = TurnTokenType.TEXT, text = text};
							}
						} catch (RegexError e) {
							warning ("%s", e.message);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}
	public struct Sync
	{
		public double time;

		public static int parse(TextReader reader, out Sync sync)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			string name = reader.name();
			sync = Sync(){ time = -1 };
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				case "time":
					sync.time = double.parse(reader.const_value());
					break;
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}
	public struct Event
	{
		public EventType type;
		public ExtentType extent;
		public string description;

		public static int parse(TextReader reader, out Event event)
		{
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 1;
			}
			int ret = 0;
			int end_depth = reader.depth();

			bool is_empty = (bool) reader.is_empty_element();
			string name = reader.name();
			event = Event(){ description = "", type = EventType.UNKNOWN, extent = ExtentType.UNKNOWN };
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				case "type":
					event.type = EventType.from_string(reader.const_value());
					break;
				case "extent":
					event.extent = ExtentType.from_string(reader.const_value());
					break;
				case "desc":
					event.description = reader.const_value();
					break;
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			if( !is_empty )
			{
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.depth() == end_depth+1 )
						{
							switch(reader.name())
							{
							default:
								ParserUtils.parse_unknown_tag(reader);
								break;
							}
						}
						else
						{
							ParserUtils.parse_unknown_tag(reader);
						}
						break;
					case ReaderType.END_ELEMENT:
						if( reader.depth() == end_depth )
						{
							return ret;
						}
						break;
					default:
						break;
					}
				}
			}
			return ret;
		}
	}


	// public int to_xml(TextWriter writer, string nodename = "siteinfo")
	// {
	// 	writer.start_element(nodename);
	// 	if(this.site_name != null)
	// 	{
	// 		writer.start_element("sitename");
	// 		writer.write_string(this.site_name);
	// 		writer.end_element();
	// 	}
	// 	if(this.base_page != null)
	// 	{
	// 		writer.start_element("base");
	// 		writer.write_string(this.base_page);
	// 		writer.end_element();
	// 	}
	// 	if(this.generator != null)
	// 	{
	// 		writer.start_element("generator");
	// 		writer.write_string(this.generator);
	// 		writer.end_element();
	// 	}
	// 	writer.start_element("case");
	// 	writer.write_string(this.case_type.to_string());
	// 	writer.end_element();
	// 	if(this.namespaces != null)
	// 	{
	// 		writer.start_element("namespaces");
	// 		foreach( Namespace cnamespace in this.namespaces )
	// 		{
	// 			cnamespace.to_xml(writer, "namespace");
	// 		}
	// 		writer.end_element();
	// 	}
	// 	writer.end_element();
	// 	return 1;
	// }

	public class Parser
	{
		public void parse(TextReader reader, out Transcription transcription)
			{
				int ret = 0;
				while( ( ret = reader.read() ) == 1 )
				{
					switch(reader.node_type())
					{
					case ReaderType.ELEMENT:
						if( reader.name() == "Trans" )
						{
							//Posix.stderr.printf("<%s>\n", reader.name());
							Transcription.parse(reader, out transcription);
							//Posix.stderr.printf("</%s>\n", reader.name());
						}
						break;
					case ReaderType.END_ELEMENT:
						break;
					case ReaderType.WHITESPACE:
					case ReaderType.SIGNIFICANT_WHITESPACE:
					case ReaderType.TEXT:
						Posix.stderr.printf("[%s]\n", reader.const_value());
						break;
					default:
						//Posix.stderr.printf("%d\t%d\t%s\t%d\n", reader.depth(), reader.node_type(), reader.name(), reader.is_empty_element());
						break;
					}
				}
			}

		public void parse_compressed_reader(string path, out Transcription transcription)
			{

				// Create a new archive object for reading
				Read archive = new Read();

				// The entry which will be read from the archive.
				weak Entry e;
 
 
				// Enable all supported compression formats
				archive.support_compression_all();
				// Enable all supported archive formats.
				archive.support_format_all();
				archive.support_format_raw();
 
				// Open the file, if it fails exit
				if (archive.open_filename(path, 4096) != Result.OK)
				{
					error("%s", archive.error_string());
				}
 
				while(archive.next_header(out e) == Result.OK)
				{
					if(!S_ISDIR(e.mode()))
					{
						parse(new TextReader.for_io (ParserUtils.read_from_archive, ParserUtils.fake_close_archive, (void*) archive, "" ), out transcription);
					}
				}
			}
	}

	namespace ParserUtils {
		private static int read_from_archive( void* context, char[] buffer, int len)
		{
			// Create a new archive object for reading
			unowned Read archive = (Read) context;
			return (int) archive.read_data(buffer, len);
		}

		private static int fake_close_archive( void* context )
		{
			return 0;
		}

		private static inline int parse_unsupported_attributes(TextReader reader)
		{
			int ret = 0;
			if( reader.node_type() != ReaderType.ELEMENT )
			{
				return 0;
			}
			string name = reader.name();
			while( ( ret = reader.move_to_next_attribute() ) == 1 )
			{
				switch(reader.name())
				{
				default:
					Posix.stderr.printf("Unsupported attibute: <%s['%s'='%s']>\n", name, reader.name(), reader.const_value());
					break;
				}
			}
			return ret;
		}
		private static inline int parse_unknown_tag(TextReader reader)
		{
			Posix.stderr.printf("Unsupported tag: <%s>\n", reader.name());
			return reader.next();
		}
	}

}

namespace TrsCLIOptions
{
	static double min_time = 0.0;
	static string output = null;
	static string domain_object = null;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] filenames = null;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] ignore_filler = null;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] exclude_filler = null;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] include_filler = null;
	[CCode (array_length = false, array_null_terminated = true)]
	static string text_transformation = null;

	static const OptionEntry[] Filter = {
		{ "min-time", 'T', 0, OptionArg.DOUBLE, ref min_time, "Minimum interval time", (string) "0.0" },
		{ "output", 'o', 0, OptionArg.FILENAME, ref output, "Output file", (string) "STDOUT" },
		{ "domain_object", 'D', 0, OptionArg.STRING, ref domain_object, "Domain object of interest", (string) "NONE" },
		{ "ignore_filler", 'X', 0, OptionArg.STRING_ARRAY, ref ignore_filler, "Ignore filler from transcription", (string) "NONE" },
		{ "exclude_filler", 'E', 0, OptionArg.STRING_ARRAY, ref exclude_filler, "Exclude filler from transcription", (string) "NONE" },
		{ "include_filler", 'I', 0, OptionArg.STRING_ARRAY, ref include_filler, "Include filler from transcription", (string) "NONE" },
		{ "text_transformation", 't', 0, OptionArg.STRING, ref text_transformation, "Text transformation to be applied (ASR, NONE)", (string) "ASR" },
		{ null }
	};

	static const OptionEntry[] General = {
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref filenames, null, "FILE" },
		{ null }
	};
}

namespace Trs
{
	class Filter
	{
		public bool keep(ref TurnToken tk)
			{
				switch(tk.type)
				{
				case Trs.TurnTokenType.TEXT:
					return true;
				case Trs.TurnTokenType.EVENT:
					return false;
				case Trs.TurnTokenType.SYNC:
					return true;
				}
				return true;
			}
	}
}

static delegate string text_transformation(string text);

int main(string[] args) {
	try {
		OptionContext opt_context = new OptionContext ("- converts .trs files into test files");
		opt_context.set_help_enabled (true);
		opt_context.add_main_entries (TrsCLIOptions.Filter, null);
		opt_context.add_main_entries (TrsCLIOptions.General, null);
		opt_context.parse (ref args);
		if( ( TrsCLIOptions.filenames == null ) )
		{
			Posix.stderr.printf("You must provide a trs input file.\n");
			Posix.stderr.printf(opt_context.get_help(true, null));
			return -1;
		}
	} catch (OptionError e) {
		Posix.stderr.printf ("%s\n", e.message);
		Posix.stderr.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
		return 1;
	}
    Xml.Parser.init();

	Trs.Parser parser = new Trs.Parser();
	Trs.Transcription transcription;
	parser.parse_compressed_reader(TrsCLIOptions.filenames[0], out transcription);
	Xml.Parser.cleanup();
//	Posix.stderr.printf("%f\n", transcription.episodes[0].sections[0].turns[0].start_time);
//	Posix.stderr.printf("%f\n", transcription.episodes[0].sections[0].turns[0].end_time);

	HashTable<string,bool> ignore_filler = new HashTable<string,bool>( str_hash, str_equal);
	foreach(string filler in TrsCLIOptions.ignore_filler)
	{
		ignore_filler.insert(filler, true);
	}
	HashTable<string,bool> exclude_filler = new HashTable<string,bool>( str_hash, str_equal);
	foreach(string filler in TrsCLIOptions.exclude_filler)
	{
		exclude_filler.insert(filler, true);
	}
	HashTable<string,bool> include_filler = new HashTable<string,bool>( str_hash, str_equal);
	foreach(string filler in TrsCLIOptions.include_filler)
	{
		include_filler.insert(filler, true);
	}
	int is_in_include = 0;
	if(TrsCLIOptions.include_filler == null)
	{
		is_in_include++;
	}
	int is_in_exclude = 0;
	text_transformation transf =  ( t => { return transform_to_asr_text(t).up(); } );
	if(TrsCLIOptions.text_transformation != null)
	{
		switch(TrsCLIOptions.text_transformation)
		{
		case "ASR":
			transf =  ( t => { return transform_to_asr_text(t).up(); } );
			break;
		case "NONE":
			transf =  ( t => { return t; } );
			break;
		default:
			transf =  ( t => { return t; } );
			break;
		}
	}

	bool is_interesting = false;
	int idx_start = 0;
	int idx = 0;
	int idx_start_last_interesting = 0;
	int idx_end_last_interesting = 0;
	double not_interesting_duration;
	Trs.TurnToken[] tokens = transcription.episodes[0].sections[0].turns[0].tokens;
	foreach(Trs.TurnToken tk in tokens)
	{
		//Posix.stderr.printf("<%s>\n", tk.type.to_string());
		switch(tk.type)
		{
		case Trs.TurnTokenType.TEXT:
			//string text = tk.text;
			//Posix.stdout.printf("%s\n", text);
			if( (is_in_include > 0) && (is_in_exclude == 0) )
			{
				is_interesting = true;
			}
			break;
		case Trs.TurnTokenType.EVENT:
			//string text = tk.event.description;
			if( include_filler.lookup_extended(tk.event.description, null, null) )
			{
				is_interesting = true;
				switch(tk.event.extent)
				{
				case Trs.ExtentType.INSTANTANEOUS:
					break;
				case Trs.ExtentType.BEGIN:
					is_in_include++;
					break;
				case Trs.ExtentType.END:
					is_in_include--;
					break;
				}
			}
			if( exclude_filler.lookup_extended(tk.event.description, null, null) )
			{
				is_interesting = false;
				switch(tk.event.extent)
				{
				case Trs.ExtentType.INSTANTANEOUS:
					break;
				case Trs.ExtentType.BEGIN:
					is_in_exclude++;
					break;
				case Trs.ExtentType.END:
					is_in_exclude--;
					break;
				}
			}
			switch(tk.event.type)
			{
			case Trs.EventType.NOISE:
				break;
			case Trs.EventType.ENTITIES:
				break;
			}
			// Posix.stdout.printf("%s\n", text);
			break;
		case Trs.TurnTokenType.SYNC:
			//Trs.Sync sync = tk.sync;
			// Posix.stdout.printf("%f\n", sync.time);
				
			if(is_interesting)
			{
				
				not_interesting_duration = tokens[idx_start].sync.time-tokens[idx_end_last_interesting].sync.time;
				if(not_interesting_duration > TrsCLIOptions.min_time)
				{
					string text = get_tokens_text(ref tokens, idx_start_last_interesting, idx_end_last_interesting, ref ignore_filler, ref exclude_filler);
					if(text.length > 0)
					{
						//Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, tokens[idx_end_last_interesting].sync.time, text);
						Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, tokens[idx_end_last_interesting].sync.time, transf(text));
					}
					idx_start_last_interesting = idx_start;
				}
				idx_end_last_interesting = idx;
			}
			idx_start = idx;
			is_interesting = false;
			break;
		}
		idx++;
	}
				
	double end_time = tokens[idx_end_last_interesting].sync.time;
	if(is_interesting)
	{
				
		not_interesting_duration = tokens[idx_start].sync.time-tokens[idx_end_last_interesting].sync.time;
		if(not_interesting_duration > TrsCLIOptions.min_time)
		{
			string text = get_tokens_text(ref tokens, idx_start_last_interesting, idx_end_last_interesting, ref ignore_filler, ref exclude_filler);
			if(text.length > 0)
			{
				//Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, tokens[idx_end_last_interesting].sync.time, text);
				Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, end_time, transf(text));
			}
			idx_start_last_interesting = idx_start;
		}
		idx_end_last_interesting = idx;
		end_time = transcription.episodes[0].sections[0].turns[0].end_time;
	}
	string text = get_tokens_text(ref tokens, idx_start_last_interesting, idx_end_last_interesting, ref ignore_filler, ref exclude_filler);
	if(text.length > 0)
	{
		//Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, tokens[idx_end_last_interesting].sync.time, text);
		Posix.stdout.printf("%f %f %s\n", tokens[idx_start_last_interesting].sync.time, end_time, transf(text));
	}
    return 0;
}

string get_tokens_text(ref Trs.TurnToken[] tokens, int idx_start, int idx_end, ref HashTable<string,bool> ignore_filler, ref HashTable<string,bool> exclude_filler)
{
	int is_in_exclude = 0;
	var builder = new StringBuilder ("");
	for(int i = idx_start; i < idx_end; i++)
	{
		switch(tokens[i].type)
		{
		case Trs.TurnTokenType.TEXT:
			if(is_in_exclude == 0)
			{
				if(builder.len > 0)
				{
					builder.append_c(' ');
				}
				builder.append(tokens[i].text);
			}
			break;
		case Trs.TurnTokenType.EVENT:
			if( exclude_filler.lookup_extended(tokens[i].event.description, null, null) )
			{
				switch(tokens[i].event.extent)
				{
				case Trs.ExtentType.INSTANTANEOUS:
					break;
				case Trs.ExtentType.BEGIN:
					is_in_exclude++;
					break;
				case Trs.ExtentType.END:
					is_in_exclude--;
					break;
				}
			}
			else
			{
				if(is_in_exclude == 0)
				{
					if(tokens[i].event.type == Trs.EventType.NOISE)
					{
						if( ! ignore_filler.lookup_extended(tokens[i].event.description, null, null) )
						{
							if(builder.len > 0)
							{
								builder.append_c(' ');
							}
							builder.append(tokens[i].event.description);
						}
					}
				}
			}
			break;
		}
	}
	return builder.str;
}



struct TokenizerR
{
	Regex regex;
	int fragment_out;
}

string transform_to_asr_text(string text)
{
	var builder = new StringBuilder ("");
	TokenizerR[] rules = {};
	try
	{
		TokenizerR r;
		Regex rx;
		rx =  new Regex("[[:space:]]+", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 0, regex = rx };
		rules += r;

		rx = new Regex("(CA|O)RD:[[:digit:]]+[\\p{L}_]*", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 0, regex = rx };
		rules += r;

		rx = new Regex("([\\p{L}_]*[^aeiouyAEIOUY]')([aeiouyAEIOUY][\\p{L}_])", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 1, regex = rx };
		rules += r;

		rx = new Regex("([\\p{L}_]*[^aeiouAEIOU]')", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 1, regex = rx };
		rules += r;

		rx = new Regex("[\\p{L}_[:digit:]º°<>-]+", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 0, regex = rx };
		rules += r;

		rx = new Regex(".", RegexCompileFlags.OPTIMIZE);
		r = TokenizerR(){ fragment_out = 0, regex = rx };
		rules += r;
	}
	catch (RegexError e)
	{
		Posix.stderr.printf ("%s\n", e.message);
		exit(-1);
	}
	string[] token_tokens = tokenize(rules, text);
	foreach(string mtk in token_tokens)
	{
		MatchInfo match;
		var punct = new Regex("^[^\\p{L}]*$", RegexCompileFlags.OPTIMIZE);
		Posix.stderr.printf ("Token \"%s\"\n", mtk);
		if ( punct.match_full(mtk, -1, 0, 0, out match ) )
		{
			Posix.stderr.printf ("Match \"%s\"\n", mtk);
			continue;
		}
		var filler = new Regex("^<.*>$", RegexCompileFlags.OPTIMIZE);
		if ( filler.match_full(mtk, -1, 0, 0, out match ) )
		{
			Posix.stderr.printf ("Fill  \"%s\"\n", mtk);
		}
		string[] tks = mtk.split("_");
		if( ( tks.length > 0 ) && (builder.len > 0) )
		{
			builder.append_c(' ');
		}
		switch( tks.length )
		{
		case 0:
			break;
		case 1:
			Posix.stderr.printf ("Fix   \"%s\"\n", tks[0]);
			builder.append(tks[0]);
			break;
		case 2:
			var number = new Regex("^(CA|O)RD:[[:digit:]]+$", RegexCompileFlags.OPTIMIZE);
			if( number.match_full(tks[0], -1, 0, 0, out match ) )
			{
				Posix.stderr.printf ("Fix   \"%s\"\n", tks[1]);
				builder.append(tks[1]);
			}
			else
			{
				Posix.stderr.printf ("Fix   \"%s\"\n", tks[0]);
				builder.append(tks[0]);
			}
			break;
		case 3:
			Posix.stderr.printf ("Fix   \"%s\"\n", tks[1]);
			builder.append(tks[1]);
			break;
		}
		foreach(string microtk in tks)
		{
			Posix.stderr.printf ("      \"%s\"\n", microtk);
		}
	}
	return builder.str;
}


string[] tokenize(TokenizerR[] rules, string text)
{
	string[] ret = {};
	MatchInfo match;
	size_t text_length = text.length;
	int offset = 0;
	int rule_nr = 0;
	while( offset < text_length )
	{
		rule_nr = 0;
		foreach(unowned TokenizerR rule in rules)
		{
			try
			{
				if ( rule.regex.match_full(text, -1, offset, RegexMatchFlags.NOTEMPTY|RegexMatchFlags.ANCHORED, out match ) )
				{
					int st, et;
					if( match.fetch_pos(rule.fragment_out, out st, out et) )
					{
						string outstring = match.fetch(rule.fragment_out);
						
						if(rule_nr > 0)
						{
							ret += outstring;
						}
						offset = et;
						break;
					}
				}
			}
			catch (RegexError e)
			{
				Posix.stderr.printf ("%s\n", e.message);
				break;
			}
			rule_nr++;
		}
	}
	return ret;
}