export interface TblTags {

}

export interface Document {
    doc_id: string;
    doc_type: string;
    text: string;
    real_id: string;
    ts: number;
    date_facet?: string;
    daily_facet?: string;
    tag_ids: string[];
    ext?: string;
    UPDATE?: boolean;
}