#***************************************************#
# This file is part of PFNET.                       #
#                                                   #
# Copyright (c) 2015-2017, Tomas Tinoco De Rubira.  #
#                                                   #
# PFNET is released under the BSD 2-clause license. #
#***************************************************#

import json
import unittest
import pfnet as pf
from . import test_cases

class TestJSON(unittest.TestCase):

    def setUp(self):

        # Networks
        self.T = 5

    def test_bus_json_string(self):

        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            for bus in net.buses:
                text = bus.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],bus.index)
                # Add more

    def test_branch_json_string(self):

        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            for branch in net.branches:
                text = branch.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],branch.index)
                # Add more

    def test_load_json_string(self):

        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            for load in net.loads:
                text = load.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],load.index)
                # Add more

    def test_gen_json_string(self):

        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            for gen in net.generators:
                text = gen.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],gen.index)
                # Add more

    def test_shunt_json_string(self):
                        
        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            for shunt in net.shunts:
                text = shunt.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],shunt.index)
                # Add more

    def test_vargen_json_string(self):
                        
        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            net.add_var_generators(net.get_load_buses(),100.,50.,30.,5,0.05)
            self.assertGreaterEqual(net.num_var_generators,1)

            for gen in net.var_generators:
                text = gen.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],gen.index)
                # Add more

    def test_bat_json_string(self):
                        
        # Multiperiod
        for case in test_cases.CASES:

            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)

            net.add_batteries(net.get_generator_buses(),20.,50.)
            self.assertGreaterEqual(net.num_batteries,1)

            for bat in net.batteries:
                text = bat.json_string
                try:
                    json_model = json.loads(text)
                    valid_json = True
                except ValueError:
                    valid_json = False
                self.assertTrue(valid_json)

                # Detailed checks
                self.assertEqual(json_model['index'],bat.index)
                # Add more

    def test_net_json_string(self):

        import time

        print '\n'
        
        # Multiperiod
        for case in test_cases.CASES:
            
            net = pf.Parser(case).parse(case,self.T)
            self.assertEqual(net.num_periods,self.T)
            
            net.add_batteries(net.get_generator_buses(),20.,50.)
            net.add_var_generators(net.get_load_buses(),100.,50.,30.,5,0.05)
            self.assertGreaterEqual(net.num_batteries,1)
            self.assertGreaterEqual(net.num_var_generators,1)

            t0 = time.time()
            text = net.json_string
            t1 = time.time()
            try:
                json_model = json.loads(text)
                valid_json = True
            except ValueError:
                valid_json = False
            self.assertTrue(valid_json)

            # Detailed checks
            self.assertEqual(json_model['num_periods'],self.T)
            self.assertEqual(json_model['base_power'],net.base_power)

            print case, t1-t0
                
    def tearDown(self):

        pass
