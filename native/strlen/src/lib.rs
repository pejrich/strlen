use rustler::NifStruct;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug, NifStruct, Clone, Copy, PartialEq, Eq)]
#[module = "SLRange"]
pub struct SLRange {
    pub start: isize,
    pub stop: isize,
    pub length: isize,
    pub step: isize,
}

impl SLRange {
    // pub fn from_sta_len(start: isize, len: isize) -> Self {
    //     return Self::from_sta_len_isize(isize::try_from(start).unwrap(), len)
    // }
    pub fn from_sta_len(start: isize, len: isize) -> Self {
        return SLRange {
            start: start,
            length: len,
            stop: start + len - 1,
            step: 1,
        };
    }
    // pub fn from_sta_sto(start: isize, stop: isize) -> Self {
    //     return Self::from_sta_sto_isize(isize::try_from(start).unwrap(), isize::try_from(stop).unwrap())
    // }

        pub fn from_sta_sto(start: isize, stop: isize) -> Self {
        return SLRange {
            start: start,
            stop: stop,
            length: stop - start + 1,
            step: 1,
        };
    }
}

#[derive(Debug, NifStruct, Clone, Copy, PartialEq, Eq)]
#[module = "StrLen.StringRange"]
pub struct SLStringRange {
    pub byte: SLRange,
    pub code: SLRange,
    pub char: SLRange,
    pub utf16: SLRange,
}

impl SLStringRange {
    pub fn zero() -> Self {
        return SLStringRange {
            byte: SLRange::from_sta_len(0, 0),
            code: SLRange::from_sta_len(0, 0),
            char: SLRange::from_sta_len(0, 0),
            utf16: SLRange::from_sta_len(0, 0),
        };
    }
    pub fn from_point(point: isize, len: SLLength) -> Self {
        return SLStringRange {
            byte: SLRange::from_sta_len(point, len.byte),
            code: SLRange::from_sta_len(point, len.code),
            char: SLRange::from_sta_len(point, len.char),
            utf16: SLRange::from_sta_len(point, len.utf16),
        };
    }

    pub fn from_range(range: SLStringRange, len: SLLength) -> Self {
        return SLStringRange {
            byte: SLRange::from_sta_len(range.byte.stop + 1, len.byte),
            code: SLRange::from_sta_len(range.code.stop + 1, len.code),
            char: SLRange::from_sta_len(range.char.stop + 1, len.char),
            utf16: SLRange::from_sta_len(range.utf16.stop + 1, len.utf16),
        };
    }
    pub fn replace(range: SLStringRange, len: SLLength) -> Self {
        return SLStringRange {
            byte: SLRange::from_sta_len(range.byte.start, len.byte),
            code: SLRange::from_sta_len(range.code.start, len.code),
            char: SLRange::from_sta_len(range.char.start, len.char),
            utf16: SLRange::from_sta_len(range.utf16.start, len.utf16),
        };
    }
    pub fn shift_after(range: SLStringRange, prev: SLStringRange) -> Self {
        return SLStringRange {
            byte: SLRange::from_sta_len(prev.byte.stop + 1, range.byte.length),
            code: SLRange::from_sta_len(prev.code.stop + 1, range.code.length),
            char: SLRange::from_sta_len(prev.char.stop + 1, range.char.length),
            utf16: SLRange::from_sta_len(prev.utf16.stop + 1, range.utf16.length),
        };
    }
}

#[derive(Debug, NifStruct, Clone, Copy, PartialEq, Eq)]
#[module = "StrLen.Length"]
pub struct SLLength {
    pub byte: isize,
    pub code: isize,
    pub char: isize,
    pub utf16: isize,
}
impl SLLength {
    pub fn new(s: &str) -> Self {
        return SLLength {
            byte: isize::try_from(s.len()).unwrap(),
            code: isize::try_from(s.chars().count()).unwrap(),
            char: isize::try_from(s.graphemes(true).count()).unwrap(),
            utf16: isize::try_from(s.encode_utf16().count()).unwrap(),
        };
    }
    pub fn zero() -> Self {
        return SLLength {
            byte: 0,
            code: 0,
            char: 0,
            utf16: 0,
        };
    }
}

#[rustler::nif]
pub fn range_from_point(len: SLLength, point: Option<isize>) -> SLStringRange {
    return SLStringRange::from_point(point.unwrap_or(0), len);
}
#[rustler::nif]
pub fn range_from_range(len: SLLength, range: SLStringRange) -> SLStringRange {
    return SLStringRange::from_range(range, len);
}

#[rustler::nif]
fn ranges(strings: Vec<&str>, r: SLStringRange) -> Vec<SLStringRange> {
    let mut result: Vec<SLStringRange> = vec![];
    let mut range: SLStringRange = r;
    for section in strings {
        let len = SLLength::new(section);
        let new_range = SLStringRange::from_range(range, len);
        result.push(new_range);
        range = new_range;
    }
    return result;
}

#[rustler::nif]
fn length(string: &str) -> SLLength {
    return SLLength::new(string);
}
#[rustler::nif]
fn replace(range: SLStringRange, string: &str) -> SLStringRange {
    return SLStringRange::replace(range, SLLength::new(string));
}

#[rustler::nif]
fn shift_after(range: SLStringRange, prev: SLStringRange) -> SLStringRange {
    return SLStringRange::shift_after(range, prev);
}

rustler::init!(
    "Elixir.StrLen.Native",
    [
        ranges,
        range_from_range,
        range_from_point,
        length,
        replace,
        shift_after
    ]
);
