import unittest
import tempfile
from pathlib import Path
from validate_uml_diagrams import intersection,segment_intersects,audit,clip_astah_endpoints,check,load_drawio,plain

class GeometryTests(unittest.TestCase):
    def test_uml_stereotype_and_generic_are_not_html_tags(self):
        self.assertEqual(plain('&lt;&lt;include&gt;&gt;'), '<<include>>')
        self.assertEqual(plain('List&lt;int&gt;'), 'List<int>')

    def test_proper_crossing(self):
        self.assertEqual(intersection((0,5),(10,5),(5,0),(5,10)),('crossing',(5.0,5.0),0))
    def test_parallel_overlap(self):
        kind,p,length=intersection((0,0),(30,0),(10,0),(40,0))
        self.assertEqual(kind,'overlap');self.assertAlmostEqual(length,20)
    def test_parallel_channels(self):
        self.assertIsNone(intersection((0,0),(30,0),(0,8),(30,8)))
    def test_general_diagonal_intersection(self):
        self.assertEqual(intersection((0,0),(10,10),(0,10),(10,0))[1],(5,5))
    def test_line_node(self):
        self.assertTrue(segment_intersects((0,10),(40,10),(5,5,20,20)))
        self.assertFalse(segment_intersects((0,5),(40,5),(5,5,20,20)))
    def test_midpoint_touch_not_crossing(self):
        self.assertEqual(intersection((0,0),(10,0),(5,0),(5,10))[0],'touch')
    def test_clip_astah_centers(self):
        points=clip_astah_endpoints([(5,5),(5,25)],(0,0,10,10),(0,20,10,10))
        self.assertEqual(points,[(5,10),(5,20)])
    def fixture(self,edges):
        return {'name':'test','format':'drawio','labels':'estimated','nodes':{'a':(0,0,10,10),'b':(30,0,10,10),'c':(0,30,10,10)},'edges':[dict(id=eid,source=src,target=dst,points=pts,label_box=label,style={}) for eid,src,dst,pts,label in edges]}
    def test_shared_endpoint_not_accidental_crossing(self):
        d=self.fixture([('ab','a','b',[(10,5),(30,5)],None),('ac','a','c',[(10,5),(10,35)],None)])
        self.assertFalse(any(i['kind'] in ('line_crossing','endpoint_on_line') for i in audit(d)['issues']))
    def test_overlap_not_exempt_when_source_shared(self):
        d=self.fixture([('ab','a','b',[(10,5),(30,5)],None),('ac','a','c',[(10,5),(20,5),(20,35),(10,35)],None)])
        self.assertIn('line_overlap',audit(d)['counts'])
    def test_label_node_and_label_line(self):
        d=self.fixture([('ab','a','b',[(10,5),(30,5)],(0,3,20,6)),('ac','a','c',[(5,10),(5,30)],(4,4,12,12))])
        counts=audit(d)['counts'];self.assertIn('label_node',counts);self.assertIn('label_line',counts);self.assertIn('label_label',counts)
    def test_off_boundary_fails(self):
        d=self.fixture([('ab','a','b',[(50,50),(30,5)],None)])
        self.assertIn('anchor_off_boundary',audit(d)['counts'])
    def test_zero_length_not_overlap(self):
        self.assertIsNone(intersection((0,0),(0,0),(0,0),(10,0)))

    def test_nested_edge_waypoints_use_parent_origin(self):
        xml = '<mxfile><diagram name="nested"><mxGraphModel><root><mxCell id="0"/><mxCell id="1" parent="0"/><mxCell id="lane_test" vertex="1" parent="1"><mxGeometry x="100" y="200" width="200" height="200"/></mxCell><mxCell id="a" vertex="1" parent="lane_test"><mxGeometry x="0" y="0" width="10" height="10"/></mxCell><mxCell id="b" vertex="1" parent="lane_test"><mxGeometry x="30" y="20" width="10" height="10"/></mxCell><mxCell id="e" edge="1" source="a" target="b" parent="lane_test" style="exitX=1;exitY=0.5;entryX=0;entryY=0.5;"><mxGeometry relative="1"><Array as="points"><mxPoint x="20" y="5"/><mxPoint x="20" y="25"/></Array></mxGeometry></mxCell></root></mxGraphModel></diagram></mxfile>'
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'nested.drawio';p.write_text(xml)
            self.assertEqual(load_drawio(p)[0]['edges'][0]['points'],[(110,205),(120,205),(120,225),(130,225)])

    def test_empty_file_cannot_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'empty.drawio';p.write_text('<mxfile/>')
            with self.assertRaisesRegex(ValueError,'empty'):check(p)

if __name__=='__main__' :unittest.main()
